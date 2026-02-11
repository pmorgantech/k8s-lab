#!/bin/bash

# Create a directory layout under K8S_ROOT
# This will hold KVM images, container images, logs, etc
set -euo pipefail

BASE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
echo "$BASE"

# shellcheck source=scripts/CONFIG.sh
. "${BASE}/CONFIG.sh"

sudo mkdir -p "$K8S_ROOT/kvm" "$K8S_ROOT/images" "$K8S_ROOT/containerd" "$K8S_ROOT/logs"
sudo chgrp kvm "$K8S_ROOT/kvm"
sudo chmod 770 "$K8S_ROOT/kvm"
