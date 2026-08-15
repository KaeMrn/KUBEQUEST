#!/usr/bin/env bash
# Live-demo script for the defense: hammer the app with `hey` to trigger the
# HPA (min 2 -> up to 8 replicas at 70% CPU, see app/helm-chart/values.yaml)
# and watch it scale in a second terminal with:
#   kubectl -n app-<env> get hpa kubequest-app -w
#
# Requires `hey` (https://github.com/rakyll/hey): brew install hey
set -euo pipefail

ENV="${1:-staging}"
HOST="${2:-$( [ "$ENV" = production ] && echo app.kubequest.local || echo staging.app.kubequest.local )}"
DURATION="${3:-5m}"
CONCURRENCY="${4:-50}"

echo "Load-testing http://${HOST}/ for ${DURATION} at concurrency ${CONCURRENCY}..."
echo "In another terminal, watch: kubectl -n app-${ENV} get hpa kubequest-app -w"
echo

hey -z "${DURATION}" -c "${CONCURRENCY}" "http://${HOST}/"
