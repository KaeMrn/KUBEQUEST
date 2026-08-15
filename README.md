# KubeQuest - Kubernetes Cluster on AWS

## Overview
A fully-equipped Kubernetes cluster on 4 AWS EC2 instances (eu-west-1), managed
end-to-end as GitOps: Terraform for infra, Kustomize + Helm for every
component, and automation scripts for a repeatable, demo-ready deployment.

## Cluster Architecture
| Node | Private IP | Role |
|------|-----------|------|
| node-1 | 10.1.35.10 | Control plane + worker |
| node-2 | 10.1.35.52 | Worker |
| node-3 | 10.1.35.197 | Worker, dedicated to ingress-nginx |
| node-4 | 10.1.35.124 | Worker, dedicated to the monitoring stack |

All 4 nodes join one Kubernetes cluster; node-3/node-4 carry a taint +
nodeSelector (`scripts/label-dedicated-nodes.sh`) so ingress and
monitoring workloads land on their own hardware rather than a physically
separate cluster.

## Repository layout
```
infra/terraform/          Provisions the 4 EC2 instances
cluster/                  GitOps repo for reusable cluster-management components
  flannel/                Pod network (remote manifest, pinned version)
  ingress-nginx/           Load balancer — 2 replicas, anti-affinity, PDB
  dashboard/               Cluster UI — behind oauth2-proxy, no public login
  monitoring/               Prometheus + Grafana — persistent storage, dedicated node
  logging/                 Loki + Promtail — persistent storage, dedicated node
  security/
    opa-gatekeeper/        Validating webhook: require resource limits + labels
    auth/                  Dex (OIDC) + oauth2-proxy fronting dashboard/Grafana
    rbac/                  Least-privilege ServiceAccounts (dashboard viewer, CI deployer)
    cert-manager/          Let's Encrypt via cert-manager (production TLS)
app/
  helm-chart/              Helm chart for the app converted from docker-compose
  gitops/                  Kustomize repo deploying app + official postgresql chart
    overlays/staging/      1 replica, relaxed HPA, staging.app.kubequest.local
    overlays/production/   3+ replicas, TLS, app.kubequest.io
    backup/                Daily pg_dump CronJob + PVC
scripts/                  Bootstrap, deploy, verify, load-test, rollback-demo
```

## Known gap
`app/helm-chart` was built structurally complete but with a **placeholder
image** — the real docker-compose app from Gandalf was never supplied to
this session. See `app/helm-chart/README.md` "Known gap" for exactly what
to swap in once you have it. Everything else (cluster components, security,
GitOps wiring, automation) is deployable as-is.

## How to rebuild from scratch (defense day)

```bash
cd infra/terraform && terraform init && terraform apply -var="key_name=kubequest"
# On every node: scripts/bootstrap-cluster.sh install-runtime
# On node-1:      scripts/bootstrap-cluster.sh init        # prints join command
# On node-2..4:   scripts/bootstrap-cluster.sh join "<command>"

scripts/deploy-all.sh staging     # or: production
scripts/verify-deployment.sh staging
```

## Live demos
```bash
scripts/load-test.sh staging       # triggers the HPA — watch: kubectl -n app-staging get hpa -w
scripts/demo-rollback.sh staging   # broken deploy -> automatic rollback (see script header for what "automatic" means here)
```

## Verify cluster health
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

See `docs/RUNBOOK.md` for the full defense-day walkthrough and talking points.
