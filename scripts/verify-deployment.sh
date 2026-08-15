#!/usr/bin/env bash
# Full health check across every component — run after deploy-all.sh, or on
# its own to sanity-check an existing cluster before the defense.
set -uo pipefail

ENV="${1:-staging}"
FAILED=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "OK   - ${desc}"
  else
    echo "FAIL - ${desc}"
    FAILED=1
  fi
}

echo "== Nodes =="
kubectl get nodes -o wide
check "all nodes Ready" bash -c "! kubectl get nodes --no-headers | grep -qv ' Ready '"

echo
echo "== Cluster components =="
check "flannel pods running"       kubectl -n kube-flannel get pods --field-selector=status.phase=Running -o name
check "ingress-nginx controller"   kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=10s
check "kubernetes-dashboard"       kubectl -n kubernetes-dashboard get pods --field-selector=status.phase=Running -o name
check "prometheus/grafana"         kubectl -n monitoring rollout status deployment/monitoring-grafana --timeout=10s
check "loki"                       kubectl -n monitoring get pods -l app=loki --field-selector=status.phase=Running -o name

echo
echo "== Security =="
check "gatekeeper controller"      kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=10s
check "constraint templates loaded" kubectl get constrainttemplates -o name
check "cert-manager"               kubectl -n cert-manager rollout status deployment/cert-manager --timeout=10s
check "dex"                        kubectl -n auth rollout status deployment/dex --timeout=10s
check "oauth2-proxy"               kubectl -n auth rollout status deployment/oauth2-proxy --timeout=10s

echo
echo "== App (namespace app-${ENV}) =="
check "app deployment"             kubectl -n "app-${ENV}" rollout status deployment/kubequest-app --timeout=10s
check "mysql"                      kubectl -n "app-${ENV}" rollout status statefulset/kubequest-db-mysql --timeout=10s
check "migration job completed"    bash -c "kubectl -n app-${ENV} get jobs -l app.kubernetes.io/component=migration -o jsonpath='{.items[-1:].status.succeeded}' | grep -q 1"
check "backup CronJob exists"      kubectl -n "app-${ENV}" get cronjob/mysql-backup -o name

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All checks passed."
else
  echo "One or more checks FAILED — see above."
  exit 1
fi
