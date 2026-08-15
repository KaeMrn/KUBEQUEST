#!/usr/bin/env bash
# Creates the app-namespace Secrets in-cluster with random values instead of
# committing credentials to Git. Run once before the first `kubectl apply -k
# app/gitops/overlays/<env>`, and again any time you want to rotate them
# (then bounce mysql + the app deployment to pick up the new values).
set -euo pipefail

NAMESPACE="${1:-app}"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

MYSQL_ROOT_PASSWORD="$(openssl rand -hex 16)"
APP_DB_PASSWORD="$(openssl rand -hex 16)"
APP_KEY="base64:$(openssl rand -base64 32)"

# Consumed by app/gitops/mysql-values.yaml (auth.existingSecret).
kubectl create secret generic mysql-auth \
  -n "$NAMESPACE" \
  --from-literal=mysql-root-password="$MYSQL_ROOT_PASSWORD" \
  --from-literal=mysql-password="$APP_DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# Consumed by app/helm-chart (values.secretName: app-db-credentials), envFrom
# in templates/deployment.yaml + templates/migrate-job.yaml. DB_PASSWORD must
# match mysql-auth's mysql-password above (same app_db user, both places).
kubectl create secret generic app-db-credentials \
  -n "$NAMESPACE" \
  --from-literal=APP_KEY="$APP_KEY" \
  --from-literal=DB_PASSWORD="$APP_DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets created in namespace '${NAMESPACE}'."
echo "mysql-auth and app-db-credentials are now populated — safe to deploy."
