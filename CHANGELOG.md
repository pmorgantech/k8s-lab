# Changelog

2026-02-13 - Added postinstall role for misc checks/installation actions.
             Added the metrics server. However, metrics server by default
             uses IP to connect to the nodes, and the nodes are presently
             using certificates without IP SANs.
           - Updated the installation to include KubeletConfiguration with
             serverTLSBootstrap: true
