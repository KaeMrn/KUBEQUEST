#!/usr/bin/env bash
# Defense-day demo: "demonstrate a full deployment process and a broken
# deployment with automatic rollback."
#
# Note on the word "automatic": vanilla Kubernetes does NOT roll back a bad
# Deployment by itself — a rollout that never becomes Ready just sits there
# (progressDeadlineSeconds only flags it as ProgressDeadlineExceeded, it
# doesn't revert anything). This script IS the automation: it watches the
# rollout and calls `kubectl rollout undo` the moment it detects failure,
# which is the standard way to get "automatic rollback" without a heavier
# tool like Argo Rollouts. Say this out loud during the defense — don't
# imply kubectl does this on its own.
set -uo pipefail

ENV="${1:-staging}"
NS="app-${ENV}"
DEPLOY="kubequest-app"
TIMEOUT="${2:-60s}"

echo "== Good deployment first, so the rollback has something valid to return to =="
kubectl -n "$NS" rollout status "deployment/${DEPLOY}" --timeout=60s

echo
echo "== Recording current image for reference =="
GOOD_IMAGE="$(kubectl -n "$NS" get deployment "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}')"
echo "Currently running: ${GOOD_IMAGE}"

echo
echo "== Rolling out a broken image (nonexistent tag) =="
kubectl -n "$NS" set image "deployment/${DEPLOY}" app="nginxdemos/hello:does-not-exist"

echo
echo "== Watching rollout — this will fail (ImagePullBackOff) =="
if kubectl -n "$NS" rollout status "deployment/${DEPLOY}" --timeout="${TIMEOUT}"; then
  echo "Rollout unexpectedly succeeded — nothing to roll back."
  exit 0
fi

echo
echo "== Broken pods (for the audience to see) =="
echo "Note: maxUnavailable=0 in the Deployment strategy means the OLD, healthy"
echo "pods are still serving traffic right now — the broken rollout never took"
echo "the app down. Worth pointing out live as the zero-downtime bonus."
kubectl -n "$NS" get pods -l app.kubernetes.io/name=kubequest-app

echo
echo "== Rollout failed as expected. Triggering automatic rollback =="
kubectl -n "$NS" rollout undo "deployment/${DEPLOY}"
kubectl -n "$NS" rollout status "deployment/${DEPLOY}" --timeout=60s

echo
echo "== Back to healthy =="
kubectl -n "$NS" get deployment "$DEPLOY" -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
kubectl -n "$NS" get pods -l app.kubernetes.io/name=kubequest-app
