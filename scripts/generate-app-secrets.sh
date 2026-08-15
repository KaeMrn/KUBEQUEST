#!/usr/bin/env bash
# Creates the app-namespace Secrets in-cluster with random values instead of
# committing credentials to Git. Run once before the first `kubectl apply -k
# app/gitops/overlays/<env>`, and again any time you want to rotate them
# (then bounce postgresql + the app deployment to pick up the new values).
set -euo pipefail

NAMESPACE="${1:-app}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

POSTGRES_PASSWORD="$(openssl rand -hex 16)"
APP_DB_PASSWORD="$(openssl rand -hex 16)"
REPLICATION_PASSWORD="$(openssl rand -hex 16)"

# Consumed by app/gitops/postgresql-values.yaml (auth.existingSecret).
kubectl create secret generic postgresql-auth \
  -n "$NAMESPACE" \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=password="$APP_DB_PASSWORD" \
  --from-literal=replication-password="$REPLICATION_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# Consumed by app/helm-chart (values.secretName: app-db-credentials), envFrom
# in templates/deployment.yaml. DATABASE_URL points at the primary; swap for
# the read-replica service in read-heavy code paths once the real app exists.
kubectl create secret generic app-db-credentials \
  -n "$NAMESPACE" \
  --from-literal=DATABASE_URL="postgresql://kubequest:${APP_DB_PASSWORD}@kubequest-db-postgresql-primary:5432/kubequest" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created in namespace '${NAMESPACE}'."
echo "postgresql-auth and app-db-credentials are now populated — safe to deploy."
