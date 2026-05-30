# nginx-ingress

## What is it
A load balancer that routes external HTTP/HTTPS traffic 
to the correct service inside the Kubernetes cluster.

## Why we need it
Pods have internal IPs not accessible from the internet.
nginx-ingress acts as the single entry point for all 
external traffic into the cluster.

## Installation
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yaml

## Verify
kubectl get pods -n ingress-nginx