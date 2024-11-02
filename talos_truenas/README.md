# About clusters

**Talos Truenas:** Cluster is created on VM using bare metal talos image. Commands utilized here are focused on this platform. In order to create cluster I had to passthrough CPU (Host Mode in Truenas) and obviously select bridge interface for networking.


## Storage

Storage configuration should be applied after cluster has been installed with Talos. We are configuring NFS so cluster can access datasets in Truenas

Create a dataset in truenas and instal CSI:

```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.9.0
```

The usage of the storage is done via storage-class and each app will have it's own.