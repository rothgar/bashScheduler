#!/usr/bin/bash
#
# A kubernetes scheduler written in bash
# dependancies: curl, shuf
# Runs against localhost:8001 by default
# Use `kubectl proxy` to proxy to master without https
#
# Author: Justin Garrison
# justingarrison.com
# @rothgar

# don't set -u because of appending to arrays
set -eo pipefail
IFS=$'\n\t'
# uncomment to see all commands in stdout
#set -x

API_URL="${API_URL:-http://localhost:8001/api/v1}"
SCHEDULER="${SCHEDULER:-bashScheduler}"

#create arrays
declare -a NODES
declare -a PODS

# get all unscheduled pods
get_pods() {
  # First we need to get the pods that have not been scheduled
  i=0
  for n in $(curl -sL "${API_URL}/pods?fieldSelector=spec.nodeName=" |\
    grep metadata -A1 | grep name | awk -F '"' '{print $4}'); do
      PODS[$i]="${n}"
      i=$((i+1))
      # Make a pod array to use later because bash associative arrays suck more
      declare -a $(echo $n | sed 's/-/_/')
  done
}

# get a list of all nodes
get_nodes() {
  i=0
  for n in $(curl -sL "${API_URL}/nodes" |\
    grep metadata -A1 | grep name | awk -F '"' '{print $4}'); do
    NODES[$i]="${n}"
    i=$((i+1))
  done
}

# arrays can have - no we need to change it to _
get_pod_array() {
  echo "$1" | sed 's/-/_/'
}

# save the pod namespace to use later
get_pod_namespace() {
  # get pods from array
  for p in "${PODS[@]}"; do
    pod_array=$(get_pod_array "${p}")
    # set $pod_array[0] = namespace
    eval ${pod_array}[0]=$(curl -sL "${API_URL}/pods?fieldSelector=spec.nodeName=" |\
      sed -n -e "/${p}/,/}/p" |\
      grep '"namespace"'|\
      awk -F '"' '{print $4}')
  done
}

# save the pod scheduler name so we can check it later
get_pod_scheduler() {
  for p in "${PODS[@]}"; do
    pod_array=$(get_pod_array "${p}")
    # set $pod_array[1] = scheduler
    eval ${pod_array}[1]=$(curl -sL "${API_URL}/pods?fieldSelector=spec.nodeName=" |\
      sed -n -e "/${p}/,/scheduler/p" |\
      grep '"scheduler'|\
      awk -F '"' '{print $4}')
  done
}

# pick a node index for our pod (returns a random number with no logic
fit_pod() {
  # put node scheduling logic here
  nodes_length=${#NODES[@]}
  # pick a random number from 0 - number of nodes
  node_index=$(shuf -i 0-${nodes_length} -n 1)
  echo "${NODES[$node_index]}"
}

# schedule_pod $pod_name $namespace $node
schedule_pod() {
    curl -sL -X POST -H "Content-Type: application/json" \
      -d '{ "apiVersion": "v1", "kind": "Binding", "metadata": 
          { "name": "'"${1}"'" }, "target": 
          { "apiVersion": "v1", "kind": "Node", "name": "'"${3}"'" } }' \
      --url "${API_URL}/namespaces/${2}/pods/${1}/binding"
}

# main loop
while true; do
  get_nodes
  get_pods
  get_pod_namespace
  get_pod_scheduler

  if [ ${#PODS[@]} -ne 0 ]; then
    for p in "${PODS[@]}"; do
      pod_array=$(get_pod_array "${p}")
      # only schedule our pods
      if [ "$(eval echo \${$pod_array[1]})" == "${SCHEDULER}" ]; then
        # get a node for the pod
        node=$(fit_pod)
        echo "Scheduling pod ${p} on node ${node}"
        RETURN_CODE=$(schedule_pod ${p} $(eval echo \${$pod_array[0]}) "${node}" |\
          grep code | awk -F ':' '/:/{gsub(/ /, "", $2); print $2}')
        if [ $RETURN_CODE == "201" ]; then
          echo "Pod ${p} scheduled."
        else
          echo "There was an error with scheduling ${p} on ${node}"
          echo "Error code: ${RETURN_CODE}"
        fi
      fi
    done; sleep 5
  else
    echo "No pods to schedule. Sleeping..."; sleep 10
  fi
  unset PODS
  unset NODES
done
