#!/usr/bin/env bash
# Builds the real app image from app/src/Dockerfile for linux/amd64 (the
# EC2 nodes). By default this is a local-only build — no registry account
# needed. Pass a registry path (and omit --local) to push.
#
# Usage:
#   ./build-and-push-app-image.sh kubequest-app v1 --local
#   ./build-and-push-app-image.sh <registry>/<repo> [tag]
# Example: ./build-and-push-app-image.sh ghcr.io/kaemrn/kubequest-app v1
set -euo pipefail

LOCAL=0
ARGS=()
for arg in "$@"; do
  if [[ "${arg}" == "--local" ]]; then
    LOCAL=1
  else
    ARGS+=("${arg}")
  fi
done

IMAGE="${ARGS[0]:?usage: build-and-push-app-image.sh <image> [tag] [--local]}"
TAG="${ARGS[1]:-v1}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Cluster nodes are x86_64 Amazon Linux; this laptop may be arm64.
docker build --platform linux/amd64 --provenance=false --sbom=false \
  -t "${IMAGE}:${TAG}" "${ROOT_DIR}/app/src"

if [[ "${LOCAL}" -eq 1 ]] || [[ "${IMAGE}" != *.* ]]; then
  echo
  echo "Built ${IMAGE}:${TAG} locally (linux/amd64). Not pushed."
  echo "Load it onto the nodes with:"
  echo "  scripts/load-app-image-to-nodes.sh ${IMAGE}:${TAG}"
  echo "Then set in app/helm-chart/values.yaml:"
  echo "  image.repository: ${IMAGE}"
  echo "  image.tag: \"${TAG}\""
  exit 0
fi

docker push "${IMAGE}:${TAG}"

echo
echo "Pushed ${IMAGE}:${TAG}"
echo "Now set in app/helm-chart/values.yaml:"
echo "  image.repository: ${IMAGE}"
echo "  image.tag: \"${TAG}\""
echo "(or override at deploy time: helm template ... --set image.repository=${IMAGE} --set image.tag=${TAG})"
