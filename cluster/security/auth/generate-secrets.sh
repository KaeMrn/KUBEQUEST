#!/usr/bin/env bash
# Creates the auth Secrets directly in-cluster with random values, instead of
# committing them to Git in plaintext (see secret-template.yaml for the shape).
# Safe to re-run: uses --dry-run=client | apply so it's idempotent, but note
# that re-running rotates the client-secret/cookie-secret, invalidating
# existing oauth2-proxy sessions and requiring Dex's static client to match.
set -euo pipefail

NAMESPACE="auth"
DEMO_PASSWORD="${1:-kubequest-demo}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

CLIENT_SECRET="$(openssl rand -hex 20)"
COOKIE_SECRET="$(openssl rand -base64 32 | head -c 32 | base64)"
PASSWORD_HASH="$(htpasswd -bnBC 10 "" "$DEMO_PASSWORD" | tr -d ':\n' | sed 's/\$2y/\$2a/')"

kubectl create secret generic dex-oauth2-proxy-client \
  -n "$NAMESPACE" \
  --from-literal=client-secret="$CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic oauth2-proxy-cookie \
  -n "$NAMESPACE" \
  --from-literal=cookie-secret="$COOKIE_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic dex-static-passwords \
  -n "$NAMESPACE" \
  --from-literal=admin-password-hash="$PASSWORD_HASH" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Demo login: admin@kubequest.local / ${DEMO_PASSWORD}"
echo "Secrets created in namespace '${NAMESPACE}'. Restart dex + oauth2-proxy to pick them up:"
echo "  kubectl -n ${NAMESPACE} rollout restart deployment/dex deployment/oauth2-proxy"
