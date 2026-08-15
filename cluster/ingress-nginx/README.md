# nginx-ingress

## What is it
A load balancer that routes external HTTP/HTTPS traffic 
to the correct service inside the Kubernetes cluster.

## Why we need it
Pods have internal IPs not accessible from the internet.
nginx-ingress acts as the single entry point for all 
external traffic into the cluster.

## Installation (GitOps, current approach)
Managed via Kustomize + the official Helm chart:

    kubectl apply -k cluster/ingress-nginx

Runs with 2 replicas spread via pod anti-affinity, resource requests/limits,
a PodDisruptionBudget (`minAvailable: 1`), and is scheduled onto the
dedicated `ingress` node (node-3) via nodeSelector/toleration — see
`scripts/label-dedicated-nodes.sh`.

## Verify
kubectl get pods -n ingress-nginx