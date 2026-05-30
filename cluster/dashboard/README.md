# Kubernetes Dashboard

## What is it
A web-based UI that lets you visualize and manage 
everything running in your Kubernetes cluster — 
pods, nodes, services, and logs — without using kubectl.

## Why we need it
Provides a visual interface for cluster management
and is useful for demonstrations and debugging.

## Installation
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

## Verify
kubectl get pods -n kubernetes-dashboard