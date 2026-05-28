#!/bin/bash
# post-apply.sh

echo "Applying kube-proxy resource limits..."
kubectl patch daemonset kube-proxy -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/resources",
    "value": {
      "requests": {"cpu": "100m", "memory": "64Mi"},
      "limits": {"cpu": "500m", "memory": "128Mi"}
    }
  }
]'

echo "Applying kubelet reservations..."
# any other post-apply kubectl commands
