Kubernetes bash scheduler
============

### This is a really bad idea

I made it because :bowtie:

I hope you learn how easy it is to extend kubernetes.

## How to run it 

Please don't ever use this on a production kubernetes cluster!!!

Ideally you'll run it against [minikube](https://github.com/kubernetes/minikube)

Use it by first creating pods that use the custom scdeduler api.

```
kubectl create -f nginx-bashScheduler.rc.yaml
```

You should see nginx pods with Pending status

```
NAME          READY     STATUS    RESTARTS   AGE
nginx-5j7lp   0/1       Pending   0          56s
nginx-g5dz9   0/1       Pending   0          56s
nginx-psma5   0/1       Pending   0          56s
```

Then proxy your localhost to the kubernetes api server

```
kubectl proxy
Starting to serve on 127.0.0.1:8001
```

Now in a new shell run

```
./scheduler.sh
```

You should see similar output to
```
$ ./scheduler.sh
Scheduling pod nginx-5j7lp on node minikubevm
Pod nginx-5j7lp scheduled.
Scheduling pod nginx-g5dz9 on node minikubevm
Pod nginx-g5dz9 scheduled.
Scheduling pod nginx-psma5 on node minikubevm
Pod nginx-psma5 scheduled.
No pods to schedule. Sleeping...
```

Look at the code and see what it's doing. Uncomment `set -x` to see all the commands run.

## Extending it

I'll leave it up to the reader to extend the scheduler to run in a pod on your kubernetes cluster. Dependancies are

* bash
* sed
* grep
* awk
* curl

You can also use TLS certificates with kubernetes default secret for pods

Have fun :shipit:
