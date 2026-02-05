# Daemonsets

Daemonesets are pods that run on every worker node.  They are designed to facilitate logging, metrics, security, or other tooling that you want to run on every node in the cluster.

```
kubectl create deployment node-exporter --image=prom/node-exporter --dry-run=client -o yaml | sed -e 's/Deployment/DaemonSet/' -e '/replicas/d' -e '/strategy/d' | tee node_exporter_daemonset.yml
```

Note that we have to remove the "replicas" and "strategy" lines from the template and replace "Deployment" with "DaemonSet" in order for our DaemonSet manifest to work.

Now we can apply it on the cluster:

```
$ kubectl apply -f node_exporter_daemonset.yml 
daemonset.apps/node-exporter created

# And we should see one node-exporter pod on each worker node:
$ kubectl get pods -o wide                                                         

NAME                  READY   STATUS    RESTARTS   AGE   IP            NODE                NOMINATED NODE   READINESS GATE
S
node-exporter-cl7gt   1/1     Running   0          15s   10.10.1.129   worker1.lab.local   <none>           <none>
node-exporter-wj585   1/1     Running   0          15s   10.10.2.103   worker2.lab.local   <none>           <none>
```

DaemonSets, since they specify pods that should run on every node, interact with drain.  An unqualified drain request will attempt to remove all pods from a node, but the DaemonSet specifies pods that should run on each node.  These two declarations are in conflict.  Indeed, if we try to drain a node:

```
$ kubectl drain worker1.lab.local
node/worker1.lab.local cordoned
error: unable to drain node "worker1.lab.local" due to error: [cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): default/node-exporter-cl7gt, kube-flannel/kube-flannel-ds-4nnkj, kube-system/kube-proxy-cxs8s, longhorn-system/engine-image-ei-b0369a5d-2jgns, longhorn-system/longhorn-csi-plugin-bzrtw, longhorn-system/longhorn-manager-pfxwl, cannot delete Pods with local storage (use --delete-emptydir-data to override): longhorn-system/longhorn-ui-6d6d8544bc-7dz7s, longhorn-system/longhorn-ui-6d6d8544bc-clqqs], continuing command...
There are pending nodes to be drained:
 worker1.lab.local
cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore): default/node-exporter-cl7gt, kube-flannel/kube-flannel-ds-4nnkj, kube-system/kube-proxy-cxs8s, longhorn-system/engine-image-ei-b0369a5d-2jgns, longhorn-system/longhorn-csi-plugin-bzrtw, longhorn-system/longhorn-manager-pfxwl
cannot delete Pods with local storage (use --delete-emptydir-data to override): longhorn-system/longhorn-ui-6d6d8544bc-7dz7s, longhorn-system/longhorn-ui-6d6d8544bc-clqqs
```

The drain command complains and the DaemonSet pods continue to run.  You must override the defaults of the drain command to explicitly ignore DaemonSet pods.  In addition, some plugins such as Longhorn require that you remove empty dir data.  This requires another additional flag:

```
$ kubectl drain worker1.lab.local --ignore-daemonsets --delete-emptydir-data
node/worker1.lab.local already cordoned
Warning: ignoring DaemonSet-managed Pods: default/node-exporter-cl7gt, kube-flannel/kube-flannel-ds-4nnkj, kube-system/kube-proxy-cxs8s, longhorn-system/engine-image-ei-b0369a5d-2jgns, longhorn-system/longhorn-csi-plugin-bzrtw, longhorn-system/longhorn-manager-pfxwl
evicting pod longhorn-system/longhorn-ui-6d6d8544bc-clqqs
evicting pod longhorn-system/csi-attacher-5f5d55bcb6-4m7hp
evicting pod longhorn-system/csi-resizer-547574c476-z9dkh
evicting pod longhorn-system/csi-attacher-5f5d55bcb6-wkr67
evicting pod longhorn-system/csi-resizer-547574c476-fw8xd
evicting pod longhorn-system/instance-manager-6c62629cfe0cad095059f3d8b5bf2cc0
evicting pod longhorn-system/longhorn-ui-6d6d8544bc-7dz7s
evicting pod longhorn-system/csi-snapshotter-774cc7b7cf-kpd7f
evicting pod longhorn-system/longhorn-driver-deployer-cf4649764-v6mx4
evicting pod longhorn-system/csi-provisioner-5db8bcb9b-b9t5j
evicting pod longhorn-system/csi-snapshotter-774cc7b7cf-jrk6n
evicting pod longhorn-system/csi-snapshotter-774cc7b7cf-vf6mb
evicting pod longhorn-system/csi-attacher-5f5d55bcb6-9ghvn
evicting pod longhorn-system/csi-provisioner-5db8bcb9b-gfth8
evicting pod longhorn-system/csi-resizer-547574c476-g46pj
evicting pod longhorn-system/csi-provisioner-5db8bcb9b-t2w4w
evicting pod local-path-storage/local-path-provisioner-689dd6b546-knrnt
I0205 13:35:21.293404 4121569 request.go:752] "Waited before sending request" delay="1.200875613s" reason="client-side throttling, not priority and fairness" verb="POST" URL="https://cp1.lab.local:6443/api/v1/namespaces/longhorn-system/pods/csi-resizer-547574c476-z9dkh/eviction"
pod/csi-snapshotter-774cc7b7cf-kpd7f evicted
pod/csi-snapshotter-774cc7b7cf-vf6mb evicted
pod/csi-attacher-5f5d55bcb6-9ghvn evicted
pod/csi-provisioner-5db8bcb9b-t2w4w evicted
pod/longhorn-driver-deployer-cf4649764-v6mx4 evicted
pod/csi-attacher-5f5d55bcb6-wkr67 evicted
pod/instance-manager-6c62629cfe0cad095059f3d8b5bf2cc0 evicted
pod/local-path-provisioner-689dd6b546-knrnt evicted
pod/csi-resizer-547574c476-z9dkh evicted
pod/csi-attacher-5f5d55bcb6-4m7hp evicted
pod/csi-provisioner-5db8bcb9b-b9t5j evicted
pod/csi-snapshotter-774cc7b7cf-jrk6n evicted
pod/csi-provisioner-5db8bcb9b-gfth8 evicted
pod/csi-resizer-547574c476-fw8xd evicted
pod/csi-resizer-547574c476-g46pj evicted
pod/longhorn-ui-6d6d8544bc-7dz7s evicted
pod/longhorn-ui-6d6d8544bc-clqqs evicted
node/worker1.lab.local drained

```
