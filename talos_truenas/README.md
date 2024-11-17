# About clusters

**Talos Truenas:** Cluster is created on VM using bare metal talos image. Commands utilized here are focused on this platform. In order to create cluster I had to passthrough CPU (Host Mode in Truenas) and obviously select bridge interface for networking.


## Storage

NFS share was greated in Truenas and storage was configure to use it.

## Other components

For storage and other components you can check them in [here](https://github.com/flmmartins/kubernetes/tree/main)