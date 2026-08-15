# Kubernetes Dashboard

## What is it
A web-based UI that lets you visualize and manage 
everything running in your Kubernetes cluster — 
pods, nodes, services, and logs — without using kubectl.

## Why we need it
Provides a visual interface for cluster management
and is useful for demonstrations and debugging.

## Installation (GitOps, current approach)
Managed via Kustomize + the official Helm chart (see `kustomization.yaml` / `values.yaml`):

    kubectl apply -k cluster/dashboard

## Verify
kubectl get pods -n kubernetes-dashboard

## Access
The dashboard has no public Ingress and no standalone login of its own here —
it's only reachable through the oauth2-proxy + dex SSO gate defined in
`../security/auth`. See that folder's README for the auth flow and for how
to get a session.