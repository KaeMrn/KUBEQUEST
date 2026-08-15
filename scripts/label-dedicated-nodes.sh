#!/usr/bin/env bash
# Labels + taints node-3/node-4 so ingress-nginx and the monitoring stack
# are scheduled onto their own dedicated hardware (matching the project
# spec's "ingress" and "monitoring" node roles) instead of competing with
# app/control-plane workloads for resources.
# Run once against a fresh cluster, right after all 4 nodes have joined.
set -euo pipefail

kubectl label node node-3 kubequest.io/role=ingress --overwrite
kubectl taint node node-3 kubequest.io/dedicated=ingress:NoSchedule --overwrite

kubectl label node node-4 kubequest.io/role=monitoring --overwrite
kubectl taint node node-4 kubequest.io/dedicated=monitoring:NoSchedule --overwrite

echo "node-3 labelled/tainted for ingress-nginx, node-4 for the monitoring stack."
kubectl get nodes --show-labels | grep -E 'node-3|node-4'
