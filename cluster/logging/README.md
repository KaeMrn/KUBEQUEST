# Loki Logging Stack

## What is it
- Loki: aggregates and stores logs from all pods 
  across all nodes
- Promtail: runs on every node and collects pod logs,
  sending them to Loki

## Why we need it
Metrics tell you what happened. Logs tell you why.
When a pod crashes, you check Loki to see the exact 
error message that caused it.

## Installation (GitOps, current approach)
Managed via Kustomize + the official Helm chart. Deploy `cluster/monitoring`
first (it creates the shared `monitoring` namespace), then:

    kubectl apply -k cluster/logging

Loki runs with a 10Gi PVC for persistence and resource requests/limits, and
is scheduled onto the dedicated `monitoring` node alongside Prometheus/Grafana.

## Verify
kubectl get pods -n monitoring | grep loki

## Access logs
Open Grafana, go to Explore, select Loki as datasource.
