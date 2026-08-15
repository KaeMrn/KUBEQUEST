# Monitoring Stack

## What is it
- Prometheus: collects metrics from all nodes every few 
  seconds (CPU, memory, disk, network, request rates)
- Grafana: visualizes those metrics as graphs and dashboards
- AlertManager: handles alerts when metrics exceed thresholds

## Why we need it
Without monitoring you cannot know if your cluster is 
healthy, when resources are running low, or why something 
crashed. Metrics answer the question "what happened?"

## Installation (GitOps, current approach)
Managed via Kustomize + the official Helm chart:

    kubectl apply -k cluster/monitoring

Prometheus/Alertmanager/Grafana all run with resource requests/limits, 15-day
Prometheus retention on a 20Gi PVC, and are scheduled onto the dedicated
`monitoring` node (node-4) via nodeSelector/toleration set up by
`scripts/label-dedicated-nodes.sh`. The Grafana admin password is never in
plaintext — the chart auto-generates a Secret, retrieved below.

## Access Grafana
From your local machine:
ssh -i kubequest.pem \
  -L 3000:localhost:3000 \
  ec2-user@ec2-34-252-96-38.eu-west-1.compute.amazonaws.com \
  kubectl --namespace monitoring port-forward svc/monitoring-grafana 3000:80

Then open http://localhost:3000
Username: admin
Password: retrieve with:
kubectl --namespace monitoring get secret monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d ; echo

## Verify
kubectl get pods -n monitoring
