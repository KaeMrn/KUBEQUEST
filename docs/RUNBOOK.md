# Defense-day runbook

Matches `project.pdf`'s "Defense" section requirements point by point.

## 1. Before presenting: fresh cluster

```bash
cd infra/terraform
terraform destroy -var="key_name=kubequest"   # only if re-provisioning from a dirty state
terraform apply -var="key_name=kubequest"
terraform output ssh_commands
```

SSH into each node and run:
```bash
../../scripts/bootstrap-cluster.sh install-runtime   # on all 4 nodes
../../scripts/bootstrap-cluster.sh init               # node-1 only — copy the printed join command
../../scripts/bootstrap-cluster.sh join "<command>"   # node-2, node-3, node-4
```

Pull the kubeconfig to your laptop:
```bash
scp -i infra/kubequest.pem ec2-user@<node-1-public-ip>:~/.kube/config ~/.kube/config
```

## 2. While presenting: deploy with nothing but kubectl/kustomize/helm

`scripts/deploy-all.sh` is a transparent wrapper — every line in it is one of
exactly the three commands the spec allows. Either run the script live, or
run its steps one at a time to narrate each:

```bash
kubectl apply -k cluster/flannel
kubectl apply -k cluster/ingress-nginx
kubectl apply -k cluster/dashboard
kubectl apply -k cluster/monitoring
kubectl apply -k cluster/logging
kubectl apply -k cluster/security/opa-gatekeeper
kubectl apply -k cluster/security/opa-gatekeeper/policies   # after the webhook is Ready
kubectl apply -k cluster/security/cert-manager
kubectl apply -f cluster/security/cert-manager/cluster-issuer.yaml
kubectl apply -k cluster/security/auth
kubectl apply -k cluster/security/rbac
kubectl apply -k app/gitops/overlays/staging
```

## 3. Demonstrate auto-scaling

```bash
kubectl -n app-staging get hpa kubequest-app -w   # terminal 1
scripts/load-test.sh staging                       # terminal 2
```
Watch replicas climb from 2 toward 8 as CPU crosses 70%, then fall back down
a few minutes after the load stops.

## 4. Demonstrate a broken deployment + rollback

```bash
scripts/demo-rollback.sh staging
```
Narrate: the new (broken) ReplicaSet never becomes Ready (ImagePullBackOff),
`maxUnavailable: 0` keeps the OLD pods serving traffic the entire time (zero
downtime), the script detects the failed rollout and runs `kubectl rollout
undo` — that script *is* the "automatic" part; vanilla Kubernetes doesn't
self-revert a stuck rollout on its own.

## 5. Talking points per spec section, mapped to files

| Spec requirement | Where |
|---|---|
| Internal load balancer | `cluster/ingress-nginx` |
| Dashboard | `cluster/dashboard` (behind `cluster/security/auth`) |
| Monitoring stack | `cluster/monitoring` |
| GitOps repo (Kustomize) | every `kustomization.yaml` under `cluster/` and `app/gitops/` |
| Logging stack | `cluster/logging` |
| Helm chart for app + official DB chart | `app/helm-chart`, `app/gitops` (bitnami/postgresql) |
| Automated deployment + status check | `scripts/deploy-all.sh`, `scripts/verify-deployment.sh` |
| Resource limits/requests | every `values.yaml` + `app/helm-chart/templates/deployment.yaml`; enforced by OPA (`cluster/security/opa-gatekeeper`) |
| Secrets | `scripts/generate-app-secrets.sh`, `cluster/security/auth/generate-secrets.sh` — never committed in plaintext |
| Labels | `commonLabels` in every `kustomization.yaml`; enforced by OPA |
| Redundancy (replicas + affinity) | `app/helm-chart/values.yaml` (anti-affinity), `cluster/ingress-nginx/values.yaml` |
| Persistent storage + backup | `app/gitops/postgresql-values.yaml` (PVCs), `app/gitops/backup/cronjob-pg-backup.yaml` |
| Validating webhook (OPA) | `cluster/security/opa-gatekeeper` |
| Auth to API + tools (dex/oauth-proxy) | `cluster/security/auth` |
| Terraform infra | `infra/terraform` |
| Let's Encrypt / cert-manager (bonus) | `cluster/security/cert-manager`, `app/gitops/overlays/production` |
| Orchestrator access permissions (bonus) | `cluster/security/rbac` |
| Zero-downtime deploys (bonus) | `app/helm-chart/values.yaml` `strategy.rollingUpdate` |
| Private registry pull (bonus) | `app/helm-chart/values.yaml` `imagePullSecrets` (wire in once there's a real private image) |

## Known gap to disclose if asked
The app itself is a structurally-complete but content-generic chart — see
`app/helm-chart/README.md`. Say so directly if asked to open the actual
application in a browser; everything around it (cluster, security, GitOps,
automation) is real and running.
