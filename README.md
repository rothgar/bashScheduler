Kubernetes bash scheduler
============

### This is a really bad idea

I made it because it was helpful for me to learn :bowtie:
I hope you learn something too.

## How to run it 

Please don't ever use this on a production kubernetes cluster!!!

Run it against a local [kind](https://kind.sigs.k8s.io/) cluster.

Use it by first creating pods that use the custom scdeduler.

```
kubectl apply -f https://raw.githubusercontent.com/rothgar/bashScheduler/main/nginx.deploy.yaml
```

You should see nginx pods with Pending status

```
NAME                     READY   STATUS    RESTARTS   AGE
nginx-56dcc974bc-8ss4m   0/1     Pending   0          49m                                              
nginx-56dcc974bc-94ltw   0/1     Pending   0          49m                                              
nginx-56dcc974bc-tnz6s   0/1     Pending   0          49m 
```

Then proxy your localhost to the kubernetes api server

```
kubectl proxy
Starting to serve on 127.0.0.1:8001
```

Now in a new terminal run

```
curl -sL https://raw.githubusercontent.com/rothgar/bashScheduler/main/scheduler.sh | bash
```

You should see similar output to
```
Assigned nginx-56dcc974bc-8ss4m to kind-control-plane
Assigned nginx-56dcc974bc-94ltw to kind-control-plane
Assigned nginx-56dcc974bc-tnz6s to kind-control-plane
```

Look at the code and see what it's doing.
Uncomment `set -x` to see all the commands run.

Have fun :shipit:
