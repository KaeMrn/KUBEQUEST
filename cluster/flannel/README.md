# Flannel

## What is it
A network plugin that creates a virtual overlay network 
across all cluster nodes, enabling pods on different 
machines to communicate with each other.

## Why we need it
Without Flannel, pods on different nodes cannot reach 
each other. Kubernetes requires a network plugin to 
function correctly.

## Installation (GitOps, current approach)
Tracked as a pinned remote manifest resource via Kustomize (not "latest",
so re-applying is reproducible):

    kubectl apply -k cluster/flannel

## Verify
kubectl get pods -n kube-flannel
