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

You can change a cluster in many ways but the best way for me is to change a file and apply that file to the nodes that way you always force yourself to do code changes and maintain a "state" file of your node. Therefore I created workers-base.yaml and controlplane-base.yaml files with non sensitive information. 

Edit these base file with your changes, save and run:


```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
<cluster_name> https://<IP>:6443 \
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


# Add new nodes

## Worker nodes

Generate config file:

```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
<cluster_name> https://<IP>:6443 \
--t worker \
--config-patch @worker-base.yaml 
```

Apply first time with insecure flag:

```
talosctl apply-config --insecure -n <new-node-ip> --file worker.yaml
```

## Control Plane nodes

TODO: Didn't do it yet

```
talosctl gen config \
--with-secrets secrets.yaml \
--with-docs=false \
--with-examples=false \
<cluster_name> https://<IP>:6443 \
--t controlplane \
--config-patch @controlplane-base.yaml 
```

Update talosconfig with new endpoint

```
talosctl config endpoint <IP>
talosctl config merge ./talosconfig
```

Test by listing endpoints and seeing the new ip:

```
talosctl get endpoints -n <IP>
```

Upload new talosconfig to vault

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