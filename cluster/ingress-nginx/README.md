# nginx-ingress

## What is it
A load balancer that routes external HTTP/HTTPS traffic 
to the correct service inside the Kubernetes cluster.

## Why we need it
Pods have internal IPs that are not accessible from the internet.
nginx-ingress acts as the single entry point for all external traffic.

## Installation
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yaml