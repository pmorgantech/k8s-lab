# Stateful Sets

Let's experiment with StatefulSets:

```
kubectl create deployment postgres --image=postgres:16 --dry-run=client -o yaml > postgres_deployment.yml
```

Modify the kind from Deployment to StatefulSet.
We should have something similar to this:

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  creationTimestamp: null
  labels:
    app: postgres
  name: postgres
spec:
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  serviceName: postgres
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: postgres
    spec:
      containers:
      - image: postgres:16
        name: postgres
        resources:
          limits:
            cpu: "2"
            memory: "1Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
```

Let's apply the deployment to the cluster:

```
$ kubectl apply -f postgres_deployment.yml 
statefulset.apps/postgres created

$ kubectl get pods -o wide
NAME         READY   STATUS             RESTARTS      AGE   IP           NODE                NOMINATED NODE   READINESS GA
TES
postgres-0   0/1     CrashLoopBackOff   3 (41s ago)   91s   10.10.1.39   worker1.lab.local   <none>           <none>
postgres-1   0/1     CrashLoopBackOff   3 (35s ago)   85s   10.10.2.46   worker2.lab.local   <none>           <none>
```

The deployment is failing, let's see why:

```
$ kubectl describe pod postgres-0
Name:             postgres-0
Namespace:        default
Priority:         0
Service Account:  default
Node:             worker1.lab.local/192.168.0.122
Start Time:       Mon, 02 Feb 2026 16:43:40 -0500
Labels:           app=postgres
                  apps.kubernetes.io/pod-index=0
                  controller-revision-hash=postgres-766966544
                  statefulset.kubernetes.io/pod-name=postgres-0
Annotations:      <none>
Status:           Running
IP:               10.10.1.39
IPs:
  IP:           10.10.1.39
Controlled By:  StatefulSet/postgres
Containers:
  postgres:
    Container ID:   containerd://d9c44f2836760e357fa737e8be99928b74c11bf873cc0629cb3c426d4cc25420
    Image:          postgres:16
    Image ID:       docker.io/library/postgres@sha256:f992505e18f114c1e5102ac4dcf00f791b44462f6a423d899320f0bbf80e386f
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Mon, 02 Feb 2026 16:45:20 -0500
      Finished:     Mon, 02 Feb 2026 16:45:20 -0500
    Ready:          False
    Restart Count:  4
    Limits:
      cpu:     2
      memory:  1Gi
    Requests:
      cpu:        1
      memory:     1Gi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-dq9wf (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
Volumes:
  kube-api-access-dq9wf:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  2m11s               default-scheduler  Successfully assigned default/postgres-0 to worker1.lab.local
  Normal   Pulling    2m10s               kubelet            Pulling image "postgres:16"
  Normal   Pulled     2m5s                kubelet            Successfully pulled image "postgres:16" in 5.322s (5.322s including waiting). Image size: 160114693 bytes.
  Normal   Created    31s (x5 over 2m5s)  kubelet            Created container: postgres
  Normal   Started    31s (x5 over 2m5s)  kubelet            Started container postgres
  Normal   Pulled     31s (x4 over 2m4s)  kubelet            Container image "postgres:16" already present on machine
  Warning  BackOff    1s (x11 over 2m3s)  kubelet            Back-off restarting failed container postgres in pod postgres-0_default(4a8d7299-26f4-4ee2-b010-26a222e787a5)

$ kubectl logs pod/postgres-0
Error: Database is uninitialized and superuser password is not specified.
       You must specify POSTGRES_PASSWORD to a non-empty value for the
       superuser. For example, "-e POSTGRES_PASSWORD=password" on "docker run".

       You may also use "POSTGRES_HOST_AUTH_METHOD=trust" to allow all
       connections without a password. This is *not* recommended.

       See PostgreSQL documentation about "trust":
       https://www.postgresql.org/docs/current/auth-trust.html
```

So we have to add some metadata to our container to get it to run.  For now (we would never do this in production!) we will simply set the auth method to trust because we are interested in testing the functionality of the statefulset, and we are not actually serving any data in our test database in this exercise.

Update the container spec:
```
    spec:
      containers:
      - image: postgres:16
        name: postgres
        resources:
          limits:
            cpu: "2"
            memory: "1Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
        env:
        - name: POSTGRES_HOST_AUTH_METHOD
          value: "trust"
```

And re-try the deployment:

```
$ kubectl delete statefulsets/postgres
statefulset.apps "postgres" deleted

$ kubectl apply -f postgres_deployment.yml 
statefulset.apps/postgres created

$ kubectl get pods -o wide                                                         NAME         READY   STATUS    RESTARTS   AGE     IP           NODE                NOMINATED NODE   READINESS GATES
postgres-0   1/1     Running   0          2m35s   10.10.2.50   worker2.lab.local   <none>           <none>
postgres-1   1/1     Running   0          2m34s   10.10.1.42   worker1.lab.local   <none>           <none>
```

We have successfully launched the statefulset into the cluster.  Let's see what PVC was created for our pods:

```
$ kubectl get pvc
No resources found in default namespace.

$ kubectl get storageclass
No resources found
```

So we update the template with both a spec.VolumeClaimTemplate and a volumeMount within the container:

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  creationTimestamp: null
  labels:
    app: postgres
  name: postgres
spec:
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  serviceName: postgres
  volumeClaimTemplates:
  - metadata:
      name: postgres-pv
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: standard

  template:
    metadata:
      creationTimestamp: null
      labels:
        app: postgres
    spec:
      containers:
      - image: postgres:16
        name: postgres
        resources:
          limits:
            cpu: "2"
            memory: "1Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
        env:
        - name: POSTGRES_HOST_AUTH_METHOD
          value: "trust"
        volumeMounts:
        - name: postgres-pv
          mountPath: /var/lib/postgresql/data
```

And re-launch.  Since this is a statefulset, we need to first delete the old statefulset and then re-apply the manifest.

```
$ kubectl delete statefulset/postgres
statefulset.apps "postgres" deleted             

$ kubectl apply -f postgres_deployment_with_volumes.yml 
statefulset.apps/postgres created

$ kubectl get pvc
NAME                     STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-pv-postgres-0   Pending                                      standard       <unset>                 2m43s

$ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
postgres-0   0/1     Pending   0          28s
```

Getting closer - the pod is not starting, and the PVC is stuck in Pending.


```
$ kubectl describe pvc/postgres-pv-postgres-0
Name:          postgres-pv-postgres-0
Namespace:     default
StorageClass:  
Status:        Pending
Volume:        
Labels:        app=postgres
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      
Access Modes:  
VolumeMode:    Filesystem
Used By:       postgres-0
Events:
  Type    Reason         Age               From                         Message
  ----    ------         ----              ----                         -------
  Normal  FailedBinding  6s (x4 over 37s)  persistentvolume-controller  no persistent volumes available for this claim and no storage class is set
```

## CSI - Enter Longhorn

We need to create a storageClass in order for the PVC to be able to be provisioned.  One of the simplest ways to do this is to install the local-path provisioner, which allows us to create storage on the worker-node to pass through to pods.  However, local-path has no redundancy if the node crashes, disk fails or we need to reshedule the container in the case of an upgrade, etc.   We can use Longhorn to allocate redundant storage for our cluster.  It simplifies allocating storage and maintaining replicas.  For our test cluster, it is easy to implement and should do the trick.


```
# We should install open-iscsi onto nodes via Ansible not on the fly
# if we really intend to use Longhorn!
for x in $(kubectl get nodes \
   -l '!node-role.kubernetes.io/control-plane' \
   -o jsonpath='{.items[*].metadata.name}') ; do 
      ssh $x 'sudo apt install -y open-iscsi; sudo systemctl enable --now iscsid'
done

kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml


$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
longhorn (default)   driver.longhorn.io      Delete          Immediate              true                   25h
```

Now that we have the longhorn CSI installed and the storageclass is present, we can use this in our statefulset manifest:

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  creationTimestamp: null
  labels:
    app: postgres
  name: postgres
spec:
  replicas: 2
  selector:
    matchLabels:
      app: postgres
  serviceName: postgres
  volumeClaimTemplates:
  - metadata:
      name: postgres-pv
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: longhorn
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: postgres
    spec:
      containers:
      - image: postgres:16
        name: postgres
        resources:
          limits:
            cpu: "2"
            memory: "1Gi"
          requests:
            cpu: "1"
            memory: "1Gi"
        env:
        - name: POSTGRES_HOST_AUTH_METHOD
          value: "trust"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-pv
          mountPath: /var/lib/postgresql/data
```

I have made a few imporant additions:   "storageClassName: longhorn" and the addition of a PGDATA env variable.

Now, let's destroy and recreate our statefulset and pvcs.

```
$ kubectl delete statefulset/postgres
statefulset.apps "postgres" deleted
petem@neo ~/workspace/career/kubernetes/k8s-lab/kubernetes $ kubectl delete pvc/postgres-pv-postgres-0
persistentvolumeclaim "postgres-pv-postgres-0" deleted
petem@neo ~/workspace/career/kubernetes/k8s-lab/kubernetes $ kubectl delete pvc/postgres-pv-postgres-1
persistentvolumeclaim "postgres-pv-postgres-1" deleted

$ kubectl apply -f postgres_deployment_with_volumes.yml 
statefulset.apps/postgres created

$ kubectl get pods -o wide
NAME         READY   STATUS              RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS GATE
S
postgres-0   1/1     Running             0          20s   10.10.1.65   worker1.lab.local   <none>           <none>
postgres-1   0/1     ContainerCreating   0          6s    <none>       worker2.lab.local   <none>           <none>

```

A minute later they are both running.  To actually connect to them, we need to create a port mapping so we can reach them from our lan workstation.  We can port-forward to our pod to connect to the postgresql service:

```
$ kubectl port-forward postgres-1 5432:5432
port-forward postgres-1 5432:5432
Forwarding from 127.0.0.1:5432 -> 5432
Forwarding from [::1]:5432 -> 5432
Handling connection for 5432

$ psql -h localhost  -U postgres
psql (16.11 (Ubuntu 16.11-0ubuntu0.24.04.1))
Type "help" for help.

postgres=#
```

Now, let's create a table and insert a row:

```
postgres=# create table test (id int primary key not null, name varchar);
CREATE TABLE
postgres=# insert into test (id, name) values (0, 'test string');
INSERT 0 1
postgres=# select * from test;
 id |    name     
----+-------------
  0 | test string
(1 row)
```

Now, to prove persistence, let's reboot the host and then check whether our database storage comes back intact:

```
# First locate the PVCs we have binded to our pods:
$ kubectl get pvc
NAME                     STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
postgres-pv-postgres-0   Bound    pvc-211c03d5-b820-4de5-9215-5805300d9806   1Gi        RWO            longhorn       <unset>                 145m
postgres-pv-postgres-1   Bound    pvc-9b0fe68a-ac82-44df-8fd3-8e9d3b137d12   1Gi        RWO            longhorn       <unset>                 145m


$ virsh reboot worker1
Domain 'worker1' is being rebooted

$ kubectl get nodes
NAME                STATUS     ROLES           AGE   VERSION
cp1.lab.local       Ready      control-plane   2d    v1.33.7
worker1.lab.local   NotReady   worker          2d    v1.33.7
worker2.lab.local   Ready      worker          2d    v1.33.7

$ kubectl get pods -o wide                                                         neo: Wed Feb  4 14:50:05 2026

NAME         READY   STATUS    RESTARTS   AGE     IP           NODE                NOMINATED NODE   READINESS GATES
postgres-0   0/1     Unknown   0          9m57s   <none>       worker1.lab.local   <none>           <none>
postgres-1   1/1     Running   0          9m43s   10.10.2.88   worker2.lab.local   <none>           <none>


# Wait for host to reboot and pod to restart.
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE                NOMINATED NODE   READINESS GATES
postgres-0   1/1     Running   0          31s   10.10.1.79   worker1.lab.local   <none>           <none>
postgres-1   1/1     Running   0          11m   10.10.2.88   worker2.lab.local   <none>           <none>

# Reconnecting to postgres-0 via the port forward and querying shows our PVC persisted and our table data is still in place:
$ kubectl port-forward postgres-1 5432:5432
port-forward postgres-1 5432:5432
Forwarding from 127.0.0.1:5432 -> 5432
Forwarding from [::1]:5432 -> 5432
Handling connection for 5432

$ psql -h localhost  -U postgres
psql (16.11 (Ubuntu 16.11-0ubuntu0.24.04.1))
Type "help" for help.

postgres=# select * from test;
 id |    name     
----+-------------
  0 | test string
(1 row)
```
