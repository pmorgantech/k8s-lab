# Lab 1 - Simple Deployment and Upgrade

In this exercise, we will create a simple deployment consisting of a few replicas of Nginx.  We will then upgrade the deployment containers.


## Deploying and Update/Rollback

First, let's create a deployment for an Nginx pod.  As of this writing, 1.29.4 is latest.  We will deliberately pick an earlier version:

```
$ kubectl create deployment nginx --image=nginx:1.28.0-alpine
deployment.apps/nginx created
```

We can watch the deployment in another terminal:

```
$ kubectl get pods -w
NAME                     READY   STATUS    RESTARTS   AGE
nginx-78b4958c96-krrfz   0/1     Pending   0          0s
nginx-78b4958c96-krrfz   0/1     Pending   0          0s
nginx-78b4958c96-krrfz   0/1     ContainerCreating   0          0s
nginx-78b4958c96-krrfz   1/1     Running             0          3s
```

The deployment has successfully created a running pod in our cluster.  Let's look at the deployment details and the pod details more closely:

```
$ kubectl logs deployment/nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/02/02 18:59:30 [notice] 1#1: using the "epoll" event method
2026/02/02 18:59:30 [notice] 1#1: nginx/1.28.0
2026/02/02 18:59:30 [notice] 1#1: built by gcc 14.2.0 (Alpine 14.2.0) 
2026/02/02 18:59:30 [notice] 1#1: OS: Linux 6.1.0-42-cloud-amd64
2026/02/02 18:59:30 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1024:524288
2026/02/02 18:59:30 [notice] 1#1: start worker processes
2026/02/02 18:59:30 [notice] 1#1: start worker process 30
2026/02/02 18:59:30 [notice] 1#1: start worker process 31
2026/02/02 18:59:30 [notice] 1#1: start worker process 32
2026/02/02 18:59:30 [notice] 1#1: start worker process 33


$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE    IP          NODE                NOMINATED NODE   READINESS GATES
nginx-78b4958c96-krrfz   1/1     Running   0          2m2s   10.10.1.2   worker1.lab.local   <none>           <none>
```

And so we can see our pod was scheduled onto worker1.lab.local worker node.  Let's say we want to run 5 nginx pods rather than just one.  We can scale our deployment dynamically:

```
$ kubectl scale deployment nginx --replicas 5
deployment.apps/nginx scaled
```

And if we check again, we should see our additional replicas running:

```
$ kubectl get pods -o wide
NAME                     READY   STATUS    RESTARTS   AGE     IP          NODE                NOMINATED NODE   READINESS GATES
nginx-78b4958c96-9mmtl   1/1     Running   0          24s     10.10.2.2   worker2.lab.local   <none>           <none>
nginx-78b4958c96-f84px   1/1     Running   0          23s     10.10.2.3   worker2.lab.local   <none>           <none>
nginx-78b4958c96-gkdxf   1/1     Running   0          23s     10.10.1.3   worker1.lab.local   <none>           <none>
nginx-78b4958c96-krrfz   1/1     Running   0          4m28s   10.10.1.2   worker1.lab.local   <none>           <none>
nginx-78b4958c96-x6lw5   1/1     Running   0          23s     10.10.2.4   worker2.lab.local   <none>           <none>
```

Now let's try upgrading our deployment to update the version of nginx container we expect:

```
$ kubectl set image deployment/nginx nginx=nginx:1.28.1-alpine
deployment.apps/nginx image updated

$ kubectl logs -f deployment/nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/02/02 18:59:30 [notice] 1#1: using the "epoll" event method
2026/02/02 18:59:30 [notice] 1#1: nginx/1.28.0
2026/02/02 18:59:30 [notice] 1#1: built by gcc 14.2.0 (Alpine 14.2.0) 
2026/02/02 18:59:30 [notice] 1#1: OS: Linux 6.1.0-42-cloud-amd64
2026/02/02 18:59:30 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1024:524288
2026/02/02 18:59:30 [notice] 1#1: start worker processes
2026/02/02 18:59:30 [notice] 1#1: start worker process 30
2026/02/02 18:59:30 [notice] 1#1: start worker process 31
2026/02/02 18:59:30 [notice] 1#1: start worker process 32
2026/02/02 18:59:30 [notice] 1#1: start worker process 33
2026/02/02 19:06:09 [notice] 1#1: signal 3 (SIGQUIT) received, shutting down
2026/02/02 19:06:09 [notice] 30#30: gracefully shutting down
2026/02/02 19:06:09 [notice] 31#31: gracefully shutting down
2026/02/02 19:06:09 [notice] 33#33: gracefully shutting down
2026/02/02 19:06:09 [notice] 32#32: gracefully shutting down
2026/02/02 19:06:09 [notice] 30#30: exiting
2026/02/02 19:06:09 [notice] 31#31: exiting
2026/02/02 19:06:09 [notice] 33#33: exiting
2026/02/02 19:06:09 [notice] 32#32: exiting
2026/02/02 19:06:09 [notice] 30#30: exit
2026/02/02 19:06:09 [notice] 31#31: exit
2026/02/02 19:06:09 [notice] 33#33: exit
2026/02/02 19:06:09 [notice] 32#32: exit
2026/02/02 19:06:09 [notice] 1#1: signal 17 (SIGCHLD) received from 30
2026/02/02 19:06:09 [notice] 1#1: worker process 30 exited with code 0
2026/02/02 19:06:09 [notice] 1#1: worker process 32 exited with code 0
2026/02/02 19:06:09 [notice] 1#1: signal 29 (SIGIO) received
2026/02/02 19:06:09 [notice] 1#1: signal 17 (SIGCHLD) received from 31
2026/02/02 19:06:09 [notice] 1#1: worker process 31 exited with code 0
2026/02/02 19:06:09 [notice] 1#1: signal 29 (SIGIO) received
2026/02/02 19:06:09 [notice] 1#1: signal 17 (SIGCHLD) received from 33
2026/02/02 19:06:09 [notice] 1#1: worker process 33 exited with code 0
2026/02/02 19:06:09 [notice] 1#1: exit
```

When we set the image in the deployment to a different version, kubernetes immediately begins to shutdown the running pods and start new ones using the image we specified.  If we look at the pods now, we will see their identifiers have changed:

```
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-775858ccf5-55s7k   1/1     Running   0          2m37s
nginx-775858ccf5-cn4w6   1/1     Running   0          2m33s
nginx-775858ccf5-cvcfp   1/1     Running   0          2m33s
nginx-775858ccf5-nqrkw   1/1     Running   0          2m36s
nginx-775858ccf5-vlkxg   1/1     Running   0          2m37s
```

```
$ kubectl set image deployment/nginx nginx=nginx:1.29.4-alpine
deployment.apps/nginx image updated

$ kubectl rollout status deployment/nginx
deployment "nginx" successfully rolled out
```

Now let's say for some reason we want to roll back to the previous version:

```
kubectl rollout undo deployment/nginx
deployment.apps/nginx rolled back

$ kubectl describe deployment/nginx
Name:                   nginx
Namespace:              default
CreationTimestamp:      Mon, 02 Feb 2026 13:59:27 -0500
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision: 5
Selector:               app=nginx
Replicas:               5 desired | 5 updated | 5 total | 5 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:         nginx:1.28.1-alpine
```

Our 1.29.4 deployment was rolled back to the previous version which was image nginx:1.28.1-alpine

## Deployment with resources

Let's create a template for a deployment so we can edit the deployment before applying it:

```
kubectl create deployment nginx --image=nginx:1.29.1-alpine --dry-run=client -o yaml > nginx_deployment.yml
```

This will generate a deployment configuration and write it to the alpine_deployment.yml file in the current directory.  Let's edit this deployment and make a few changes:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mynginx
  name: mynginx
spec:
  replicas: 5
  selector:
    matchLabels:
      app: mynginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: mynginx # this is the label for the pod template
    spec:
      containers:
      - image: nginx:1.29.1-alpine
        name: nginx
        resources:
          limits:
            cpu: "1"
            memory: "100Mi"
          requests:
            cpu: "1"
            memory: "100Mi"
```

When we apply this deployment to our cluster, it will perform rolling upgrades by creating up to maxSurge additional pods, and allowing only maxUnavailable pods to be not running out of the desired number of replica pods.  This performs a controlled rolling update.  Additionally, we introduced some limits and resources:

**Limits** control the maximum amount of resources a pod can obtain, whereas **resources** specify the minimum amount of resources a pod must be granted.

In this case, I require at least 1 cpu for each nginx pod, and when I apply the deployment:

```
NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE                NOMINATED NODE   READINES
S GATES
mynginx-599d4dfbdd-88h69   1/1     Running   0          4m50s   10.10.2.31   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-bcswq   1/1     Running   0          4m50s   10.10.2.32   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-c4fj2   1/1     Running   0          4m50s   10.10.2.33   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-gv488   0/1     Pending   0          4m48s   <none>       <none>              <none>           <none>
mynginx-599d4dfbdd-nx7lh   0/1     Pending   0          4m48s   <none>       <none>              <none>           <none>
mynginx-687c9ddd7c-nnrq5   1/1     Running   0          7m40s   10.10.2.28   worker2.lab.local   <none>           <none>
```

Two pods are in the pending state.  Let's see why by examining one of the pods stuck in the Pending state:

```
$ kubectl describe pod mynginx-599d4dfbdd-gv488
Name:             mynginx-599d4dfbdd-gv488
Namespace:        default
Priority:         0
Service Account:  default
Node:             <none>
Labels:           app=mynginx
                  pod-template-hash=599d4dfbdd
Annotations:      <none>
Status:           Pending
IP:               
IPs:              <none>
Controlled By:    ReplicaSet/mynginx-599d4dfbdd
Containers:
  nginx:
    Image:      nginx:1.29.1-alpine
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     1
      memory:  100Mi
    Requests:
      cpu:        1
      memory:     100Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-tx77j (ro)
Conditions:
  Type           Status
  PodScheduled   False 
Volumes:
  kube-api-access-tx77j:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Guaranteed
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  43s (x5 over 6m5s)  default-scheduler  0/3 nodes are available: 1 Insufficient cpu, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }, 1 node(s) had untolerated taint {node.kubernetes.io/unreachable: }. preemption: 0/3 nodes are available: 1 No preemption victims found for incoming pod, 2 Preemption is not helpful for scheduling.
```

The pod is not starting due to insufficient CPU resources on our cluster.  Let's see why:

```
$ kubectl get nodes
NAME                STATUS     ROLES           AGE    VERSION
cp1.lab.local       Ready      control-plane   131m   v1.33.7
worker1.lab.local   NotReady   <none>          131m   v1.33.7
worker2.lab.local   Ready      <none>          131m   v1.33.7
```

Okay, so we have one running worker node:  worker2.lab.local.  Let's see what resources it has available:

```
$ kubectl describe node worker2.lab.local
Name:               worker2.lab.local
CreationTimestamp:  Mon, 02 Feb 2026 13:56:12 -0500
Taints:             <none>
Unschedulable:      false

Addresses:
  InternalIP:  192.168.0.123
  Hostname:    worker2.lab.local
Capacity:
  cpu:                4
  ephemeral-storage:  20431752Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             8144168Ki
  pods:               110
Allocatable:
  cpu:                4
  ephemeral-storage:  18829902613
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             8041768Ki

Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                3200m (80%)  4 (100%)
  memory             450Mi (5%)   400Mi (5%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
```

From this output, we can see that we have 4 cpus allocatable, and we have allocated all 4 of them.  In order for the other pods to start, we would need more resources on the cluster.  Let's bring up worker1 and see what happens:

```
$ virsh start worker1
Domain 'worker1' started

$ kubectl get nodes
NAME                STATUS     ROLES           AGE    VERSION
cp1.lab.local       Ready      control-plane   136m   v1.33.7
worker1.lab.local   NotReady   <none>          136m   v1.33.7
worker2.lab.local   Ready      <none>          136m   v1.33.7

# A minute later:
$ kubectl get nodes 
NAME                STATUS   ROLES           AGE    VERSION
cp1.lab.local       Ready    control-plane   137m   v1.33.7
worker1.lab.local   Ready    <none>          136m   v1.33.7
worker2.lab.local   Ready    <none>          136m   v1.33.7

kubectl get pods -o wide
NAME                       READY   STATUS              RESTARTS   AGE   IP           NODE                NOMINATED NODE
READINESS GATES
mynginx-599d4dfbdd-88h69   1/1     Running             0          12m   10.10.2.31   worker2.lab.local   <none>
<none>
mynginx-599d4dfbdd-bcswq   1/1     Running             0          12m   10.10.2.32   worker2.lab.local   <none>
<none>
mynginx-599d4dfbdd-c4fj2   1/1     Running             0          12m   10.10.2.33   worker2.lab.local   <none>
<none>
mynginx-599d4dfbdd-gv488   0/1     ContainerCreating   0          12m   <none>       worker1.lab.local   <none>
<none>
mynginx-599d4dfbdd-nx7lh   0/1     ContainerCreating   0          12m   <none>       worker1.lab.local   <none>
<none>
mynginx-687c9ddd7c-nnrq5   1/1     Running             0          15m   10.10.2.28   worker2.lab.local   <none>
<none>

# And again shortly thereafter:
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS
GATES
mynginx-599d4dfbdd-88h69   1/1     Running   0          12m   10.10.2.31   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-bcswq   1/1     Running   0          12m   10.10.2.32   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-c4fj2   1/1     Running   0          12m   10.10.2.33   worker2.lab.local   <none>           <none>
mynginx-599d4dfbdd-gv488   1/1     Running   0          12m   10.10.1.25   worker1.lab.local   <none>           <none>
mynginx-599d4dfbdd-nx7lh   1/1     Running   0          12m   10.10.1.24   worker1.lab.local   <none>           <none>
```

So kubernetes automatically scheduled the Pending pods onto worker1 when it became available.

## Rebooting a node

To safely reboot a node (ie without crashing pods or having to wait for detection of dead node and pods), we can drain and cordon a node before rebooting.

**cordon** prevents the scheduler from scheduling new pods onto a node
**drain** removes the running pods from a node, rescheduling them onto other workers

```
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS
GATES
mynginx-74c7c55f54-76jh8   1/1     Running   0          42s   10.10.2.39   worker2.lab.local   <none>           <none>
mynginx-74c7c55f54-b6x7x   1/1     Running   0          41s   10.10.2.40   worker2.lab.local   <none>           <none>
mynginx-74c7c55f54-crhlr   1/1     Running   0          41s   10.10.1.33   worker1.lab.local   <none>           <none>
mynginx-74c7c55f54-ngwkn   1/1     Running   0          43s   10.10.2.38   worker2.lab.local   <none>           <none>
mynginx-74c7c55f54-pdmfc   1/1     Running   0          43s   10.10.1.32   worker1.lab.local   <none>           <none>

$ kubectl cordon worker2.lab.local
node/worker2.lab.local cordoned

$ kubectl get nodes
NAME                STATUS                     ROLES           AGE    VERSION
cp1.lab.local       Ready                      control-plane   149m   v1.33.7
worker1.lab.local   Ready                      <none>          148m   v1.33.7
worker2.lab.local   Ready,SchedulingDisabled   <none>          148m   v1.33.7


$ kubectl drain worker2.lab.local
node/worker2.lab.local already cordoned
error: unable to drain node "worker2.lab.local" due to error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-flannel/kube-flannel-ds-kw62z, kube-system/kube-proxy-n5hhr, continuing command...
There are pending nodes to be drained:
 worker2.lab.local
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): kube-flannel/kube-flannel-ds-kw62z, kube-system/kube-proxy-n5hhr
```

There are some required pods on this node which we will have to ignore:

```
$ kubectl drain worker2.lab.local --ignore-daemonsets --delete-emptydir-data
node/worker2.lab.local already cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-kw62z, kube-system/kube-proxy-n5hhr
evicting pod default/mynginx-74c7c55f54-ngwkn
evicting pod default/mynginx-74c7c55f54-76jh8
evicting pod default/mynginx-74c7c55f54-b6x7x
pod/mynginx-74c7c55f54-b6x7x evicted
pod/mynginx-74c7c55f54-ngwkn evicted
pod/mynginx-74c7c55f54-76jh8 evicted
node/worker2.lab.local drained

$ kubectl get pods -o wide
NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE                NOMINATED NODE   READINES
S GATES
mynginx-74c7c55f54-crhlr   1/1     Running   0          2m32s   10.10.1.33   worker1.lab.local   <none>           <none>
mynginx-74c7c55f54-hcrxz   1/1     Running   0          17s     10.10.1.35   worker1.lab.local   <none>           <none>
mynginx-74c7c55f54-jzd2q   1/1     Running   0          17s     10.10.1.36   worker1.lab.local   <none>           <none>
mynginx-74c7c55f54-pdmfc   1/1     Running   0          2m34s   10.10.1.32   worker1.lab.local   <none>           <none>
mynginx-74c7c55f54-vmhzp   1/1     Running   0          17s     10.10.1.34   worker1.lab.local   <none>           <none>
```

Kubernetes has evacuated worker2.lab.local, allowing it to be rebooted safely without causing unexpected crashes or delays.  After rebooting you must uncordon to remove the SchedulingDisabled state:

```
$ kubectl uncordon worker2.lab.local
node/worker2.lab.local uncordoned

$ kubectl get nodes
NAME                STATUS   ROLES           AGE    VERSION
cp1.lab.local       Ready    control-plane   150m   v1.33.7
worker1.lab.local   Ready    <none>          150m   v1.33.7
worker2.lab.local   Ready    <none>          150m   v1.33.7
```

## Recovering more quickly from unexpected node loss

If a node dies, it can take several minutes before pods are rescheduled onto other nodes.  This can be adjusted via some deployment configuration:

```
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 10
```

This informs kubernetes that pods will be deleted if the node is unavailable for 10 seconds.

