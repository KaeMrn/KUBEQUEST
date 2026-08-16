#!/usr/bin/env bash
# Deploys the entire KubeQuest stack in the correct dependency order.
# Every step below is just kubectl apply -f/-k, kustomize, or helm — no
# hidden abstraction, matching the project's deployment constraints.
#
# Usage: ./deploy-all.sh [staging|production]
set -euo pipefail

ENV="${1:-staging}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLUSTER_DIR="${ROOT_DIR}/cluster"
APP_DIR="${ROOT_DIR}/app/gitops"

wait_for() {
  local ns="$1" deploy="$2" timeout="${3:-180s}"
  kubectl -n "$ns" rollout status "deployment/${deploy}" --timeout="${timeout}"
}

echo "== 1. Networking (Flannel) =="
kubectl apply -k "${CLUSTER_DIR}/flannel"

echo "== 2. Dedicate node-3/node-4 to ingress/monitoring =="
"${ROOT_DIR}/scripts/label-dedicated-nodes.sh"

echo "== 3. Ingress controller =="
kubectl apply -k "${CLUSTER_DIR}/ingress-nginx"
wait_for ingress-nginx ingress-nginx-controller

echo "== 4. Dashboard =="
kubectl apply -k "${CLUSTER_DIR}/dashboard"

echo "== 5. Monitoring (Prometheus + Grafana) =="
kubectl apply -k "${CLUSTER_DIR}/monitoring"
wait_for monitoring monitoring-grafana

echo "== 6. Logging (Loki + Promtail) =="
kubectl apply -k "${CLUSTER_DIR}/logging"

echo "== 7. OPA Gatekeeper (webhook first, policies after CRDs are Ready) =="
kubectl apply -k "${CLUSTER_DIR}/security/opa-gatekeeper"
kubectl -n gatekeeper-system wait --for=condition=Available deployment/gatekeeper-controller-manager --timeout=120s
kubectl apply -k "${CLUSTER_DIR}/security/opa-gatekeeper/policies"

echo "== 8. cert-manager (webhook first, ClusterIssuer after) =="
kubectl apply -k "${CLUSTER_DIR}/security/cert-manager"
kubectl -n cert-manager wait --for=condition=Available deployment/cert-manager-webhook --timeout=120s
kubectl apply -f "${CLUSTER_DIR}/security/cert-manager/cluster-issuer.yaml"
kubectl apply -f "${CLUSTER_DIR}/security/cert-manager/selfsigned-issuer.yaml"

echo "== 9. Auth (Dex + oauth2-proxy) =="
"${CLUSTER_DIR}/security/auth/generate-secrets.sh"
kubectl apply -k "${CLUSTER_DIR}/security/auth"

echo "== 10. RBAC (dashboard read-only viewer) =="
kubectl apply -k "${CLUSTER_DIR}/security/rbac"

echo "== 11. App secrets (env: ${ENV}) =="
"${ROOT_DIR}/scripts/generate-app-secrets.sh" "app-${ENV}"

echo "== 12. Guard: has the real app image been built and pushed? =="
if grep -q "REPLACE_ME/kubequest-app" "${ROOT_DIR}/app/helm-chart/values.yaml"; then
  echo "app/helm-chart/values.yaml still has the placeholder image."
  echo "Run: scripts/build-and-push-app-image.sh kubequest-app v1 --local"
  echo "then: scripts/load-app-image-to-nodes.sh"
  exit 1
fi

echo "== 13. App + MySQL (env: ${ENV}) =="
kubectl apply -k "${APP_DIR}/overlays/${ENV}"

echo "== 14. Wait for MySQL, then run migrations, then wait for the app =="
kubectl -n "app-${ENV}" rollout status statefulset/kubequest-db-mysql --timeout=180s
LATEST_MIGRATE_JOB="$(kubectl -n "app-${ENV}" get jobs -l app.kubernetes.io/component=migration -o jsonpath='{.items[-1:].metadata.name}')"
kubectl -n "app-${ENV}" wait --for=condition=complete "job/${LATEST_MIGRATE_JOB}" --timeout=120s
wait_for "app-${ENV}" kubequest-app

echo
echo "Deployment complete. Run scripts/verify-deployment.sh for a full health check."
