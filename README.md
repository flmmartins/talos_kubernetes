# Kubernetes

This repository configure kubernetes cluster by using Talos. Each folder in this repo has configurations for a given cluster. For example, folder talos_truenas contain configurations for a cluster named talos_truenas. Hopefuly in the future talos can be used for multiple platforms and more folders will be created here.

# Setup


## Install talos cli

```
brew install talosctl
brew install siderolabs/tap/talosctl
```

## Download and install talosconfig

Download talosconfig from vault and run:

```
talosctl kubeconfig --nodes <IP> --endpoints <IP> --talosconfig=./talosconfig
```


Talos has a similar concept of a kubeconfig, you can store the talos config globaly in your ~/.talos folder so you don't have to use it in every command from this readme:

```
talosctl config merge ./talosconfig
```

Test again using the talos config from your local folder:

```
talosctl -n <IP> health
```

You can add nodes to the config file so you don't have to always keep doing -n. You can do this by:

```
talosctl config node IP1 IP2
```

# Useful debugging commands

Health checks:
```
talosctl -n <IP> health
talosctl -n <IP> dashboard
```

Talos OS service state:
```
talosctl -n <IP> services
```

Logs for a service:

```
talosctl -n <IP> logs <service>
```

Check system containers:

```
talosctl -n <IP> containers -k
```

Logs of system containers (you must select the second one from the above output)

````
talosctl -n <IP> logs -k kube-system/....
````


# Get current configuration

```
talosctl get machineconfig -n <IP> -o yaml
```

# Change configuration

When you create a talos cluster you generate several files with `talosctl gen config`. All the files contain sensitive information and therefore they were not added to this repository. Below is a list and how they can be obtained

* **worker.yaml:** State file of you worker nodes. This configuration is auto generated.
* **controlplane.yaml:** State file of your controlplane. This configuration file is auto generated.
* **talosconfig:** This file should be saved in vault
* **secrets.yaml:** This file should be saved in vault

Secrets.yaml should be downloaded to your laptop and talosconfig should installed in your laptop as well as mentioned above.

You can change a cluster in many ways but the best way for me is to change a file and apply that file to the nodes that way you always force yourself to do code changes and maintain a "state" file of your node. Therefore I created **workers-base.yaml** and **controlplane-base.yaml** files with non sensitive information. 

Edit these base file with your changes. Now backup your old configuration with:

```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
<cluster_name> https://CONTROL_PLANE_IP:6443 \
--t <type_of_change> > backup.yaml 
```

Now generate new config with your changes:
```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
<cluster_name> https://CONTROL_PLANE_IP:6443 \
--t <type_of_change> \
--config-patch @controlplane-base.yaml 
```

Where type is worker, controlplane, talosconfig. If you set -t controplane it will generate you a controlplane.yaml for example. 

Omit -t to change all files.

Choose the node you want to apply with -n.

You can use mode **try** which is pretty nice to test. What try does: Apply change with automatic revert (--mode=try): change is applied immediately (if not possible, returns an error), and reverts it automatically in 1 minute if no configuration update is applied

```
talosctl apply-config -n <IP> -m=try --file controlplane.yaml
talosctl apply-config -n <IP> --file controlplane.yaml 
```

There's also a mode flag which allows you to say if node can restart or not

**Important:** Gen config command is not perfect. Sometimes after running it you will see duplicated entries and that will be bad for your cluster.

# Upgrades

Talos will control upgrades. It recommends going from latest patch of the current version and then switching major/minor.

## Talos OS
Upgrading OS will not change Kubernetes Version

Before upgrading Kubernetes upgrade talosctl on your laptop. It will allow you to go to the latest version of kubernetes available.

```
brew upgrade talosctl
```

```
talosctl upgrade --nodes NODE_IP --image ghcr.io/siderolabs/installer:v1.9.5
```

It might be that one pod will get stuck during the node drain prologing the upgrade, you can enter and check.

Check health afterwards: `talosctl -n CONTROL_PLANE_IP health`

After upgrade make sure to update base config and generate a new worker/controlplane config:

```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
talos_truenas https://CONTROL_PLANE_IP:6443
```

Compare controlplane.yaml, worker.yaml, talosconfig files against base to see if something changed. Versions are expected to change and those should be updated at least. On talosconfig it was observed that certificate changed so you can do `talosctl config merge ./talosconfig`

# Upgrade Kubernetes

Check Talos and Kubernetes version compatibility.

Before upgrading Kubernetes upgrade talosctl on your laptop:

```
brew upgrade talosctl
```

To trigger a Kubernetes upgrade, issue a command specifying the version of Kubernetes to ugprade to, such as:

```
talosctl --nodes <controlplane node> upgrade-k8s --to 1.32.2
```

Note that the --nodes parameter specifies the control plane node to send the API call to, but all members of the cluster will be upgraded.

To check what will be upgraded you can run talosctl upgrade-k8s with the --dry-run flag.

Check health afterwards: `talosctl -n CONTROL_PLANE_IP health`

After upgrade make sure to update base config and generate a new worker/controlplane config:

```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
talos_truenas https://CONTROL_PLANE_IP:6443
```

Compare controlplane.yaml, worker.yaml, talosconfig files against base to see if something changed. Versions are expected to change and those should be updated at least. On talosconfig it was observed that certificate changed so you can do `talosctl config merge ./talosconfig`

# Add new nodes

Install talos ISO in one machine. Once you boot you will be able to configure IPs. More info on Notion

More info can be found on [scale-up](https://www.talos.dev/v1.9/talos-guides/howto/scaling-up/)


If you already have the config in your machine it's just a matter of applying it to the new IP depending of a machine is controlplane or worker. If you don't have the config files ready, check the change configuration section. It will generate a file based on the worker-base or controlplane-base.

## Workers

```
talosctl apply-config --insecure -n <new-node-ip> --file worker.yaml
```

To apply labels, instead of generating a config file only for that you can do:

```
talosctl patch mc --nodes <node_ip> --patch '[{"op": "add", "path": "/machine/nodeLabels", "value": {"env":"prd","number":"1"}}]'
```

## Control Plane

```
talosctl apply-config --insecure -n <new-node-ip> --file controlplane.yaml
```

Update talosconfig with new endpoint

```
talosctl config endpoint <IP>
talosctl config merge ./talosconfig
```

The merge command can mess up the talos config file so it's best to just add endpoints manually to the file if that's the case.

Test by listing endpoints and seeing the new ip:

```
talosctl get endpoints -n <IP>
```

Upload new talosconfig to vault

## Adding a node as controlplane and worker

When adding a second controlplane performance was horrible. Reading talos documentation: they require an odd number of controlplanes so I had to add a node as controlplane and worker in order to have an odd number.

```
cluster:
  allowSchedulingOnControlPlanes: true
```

# Deleting a node

`talosctl -n IP.of.node.to.remove reset`
`kubectl delete node`

# Generating vanila configuration without changes

When you create a talos cluster you generate several files with `talosctl gen config` and then you apply them to nodes. If you need to re-generate this same files without changes:

```
talosctl gen config \
   --with-secrets secrets.yaml \
   --with-docs=false \
   --with-examples=false \
   <cluster_name> https://<IP>:6443
```


# Configuring a cluster from scratch

## First Control Plane

Generate secrets as separate file 
```
talosctl gen secrets -o secrets.yaml
talosctl gen config --with-secrets secrets.yaml <cluster_name> https://<IP>:6443
```

Apply config:

```
talosctl apply-config --insecure -n <IP> --file controlplane.yaml
```

**!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!**
**!!Only run this one time!!**
**!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!**
```
talosctl bootstrap --nodes <IP> --endpoints <IP> --talosconfig=./talosconfig
```

Download config file:

```
talosctl kubeconfig --nodes <IP> --endpoints <IP> --talosconfig=./talosconfig
```

Do some health checks:

```
talosctl --nodes <IP> --endpoints <IP> health \
   --talosconfig=./talosconfig
talosctl --nodes <IP> --endpoints <IP> dashboard \
   --talosconfig=./talosconfig
```


After everything is working you can add endpoint to your talosconfig in all commands with:

```
talosctl config endpoint <IP>
```

Talos has a similar concept of a kubeconfig, you can store the talos config globaly in your ~/.talos folder so you don't have to use it also in every command:

```
talosctl config merge ./talosconfig
```

Test again:

```
talosctl -n <IP> health
```

# About clusters

Information about each cluster is inside its folder