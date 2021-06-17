#!/usr/bin/env bash
#
# A kubernetes scheduler written in bash
# dependancies: kubectl, curl
# Runs against localhost:8001 by default
# Use `kubectl proxy` to proxy to master without https
#
# Author: Justin Garrison
# justingarrison.com
# @rothgar

set -eo pipefail
# uncomment to see all commands in stdout
# set -x

SERVER="${SERVER:-localhost:8001}"
SCHEDULER="${SCHEDULER:-bashScheduler}"

while true; do
  # Get a list of all our pods in pending state
  for POD in $(kubectl --server ${SERVER} get pods \
              --output jsonpath='{.items..metadata.name}' \
              --all-namespaces \
              --field-selector=status.phase==Pending); do

    # Get the pod namespace
    NAMESPACE=$(kubectl get pod ${POD} \
                --output jsonpath='{.metadata.namespace}')

    # Get an array for all of the nodes
    # We could optionally check if the nodes are ready
    NODES=($(kubectl --server ${SERVER} get nodes \
            --output jsonpath='{.items..metadata.name}'))

    # Store a number for the length of our NODES array
    NODES_LENGTH=${#NODES[@]}

    # Randomly select a node from the array
    # $RANDOM % $NODES_LENGTH will be the remainder
    # of a random number divided by the length of our nodes
    # In the case of 1 node this is always ${NODES[0]}
    NODE=${NODES[$[$RANDOM % $NODES_LENGTH]]}

    # Bind the current pod to the node selected
    curl -silent --show-error --fail \
      --header "Content-Type:application/json" \
      --request POST \
      --data '{"apiVersion":"v1",
              "kind": "Binding", 
              "metadata": {
                "name": "'${POD}'"
                }, 
              "target": {
                "apiVersion": "v1", 
                "kind": "Node", 
                "name": "'${NODE}'"
                }
              }' \
      http://${SERVER}/api/v1/namespaces/${NAMESPACE}/pods/${POD}/binding/ \
      && echo "Assigned ${POD} to ${NODE}" \
      || echo "Failed to assign ${POD} to ${NODE}"
  done

  sleep 4s
done
