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

## Installation
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true

## Verify
kubectl get pods -n monitoring | grep loki

## Access logs
Open Grafana, go to Explore, select Loki as datasource.
