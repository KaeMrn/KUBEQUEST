# Flannel

## What is it
A network plugin that creates a virtual overlay network 
across all cluster nodes, enabling pods on different 
machines to communicate with each other.

## Why we need it
Without Flannel, pods on different nodes cannot reach 
each other. Kubernetes requires a network plugin to 
function correctly.

## Installation
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

## Verify
kubectl get pods -n kube-flannel
