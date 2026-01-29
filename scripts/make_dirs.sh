#!/bin/sh

# Create a directory layout under K8S_ROOT
# This will hold KVM images, container images, logs, etc

BASE="$(/bin/dirname $0)"
echo $BASE
. "${BASE}/CONFIG.sh"

/bin/sudo su - root -c '/bin/mkdir -p "'$K8S_ROOT'/kvm/"; cd "'$K8S_ROOT'"; mkdir images snapshots templates'
/bin/sudo su - root -c '/bin/chgrp kvm "'$K8S_ROOT'/kvm"'
/bin/sudo su - root -c '/bin/mkdir -p "'$K8s_ROOT'/containerd"'
for x in pods plugins plugins_registry; do
   /bin/sudo su - root -c '/bin/mkdir -p "'$K8S_ROOT'/kubelet/$x"'
done
/bin/sudo su - root -c '/bin/mkdir -p "'$K8S_ROOT'/logs/pods"'

