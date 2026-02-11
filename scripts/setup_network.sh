#!/bin/bash
#
# Configure networking for K8s lab.
# This script is useful for my Mint desktop and particular NM-based
# network config.  YMMV.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/CONFIG.sh
source "$SCRIPT_DIR/CONFIG.sh"

/usr/bin/sudo /usr/bin/nmcli con add type bridge ifname "${BRIDGE_NAME}"
/usr/bin/sudo /usr/bin/nmcli con add type bridge-slave ifname "${NIC}" master "${BRIDGE_NAME}"
/usr/bin/sudo /usr/bin/nmcli con modify "${BRIDGE_NAME}" ipv4.method auto
/usr/bin/sudo /usr/bin/nmcli con modify "${BRIDGE_NAME}" bridge.stp yes
/usr/bin/sudo /usr/bin/nmcli con modify "${BRIDGE_NAME}" bridge.forward-delay 4
/usr/bin/sudo /usr/bin/nmcli con up "${BRIDGE_NAME}"
