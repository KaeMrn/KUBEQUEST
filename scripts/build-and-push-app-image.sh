#!/usr/bin/env bash
# Builds the real app image from app/src/Dockerfile and pushes it to a
# registry the cluster can pull from. Satisfies "create some lightweight
# Docker images" / "pull Docker images from a private registry" bonuses if
# you point REGISTRY at a private one (see imagePullSecrets in values.yaml).
#
# Usage: ./build-and-push-app-image.sh <registry>/<repo> [tag]
# Example: ./build-and-push-app-image.sh ghcr.io/kaemrn/kubequest-app v1
set -euo pipefail

IMAGE="${1:?usage: build-and-push-app-image.sh <registry>/<repo> [tag]}"
TAG="${2:-latest}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

docker build -t "${IMAGE}:${TAG}" "${ROOT_DIR}/app/src"
docker push "${IMAGE}:${TAG}"

echo
echo "Pushed ${IMAGE}:${TAG}"
echo "Now set in app/helm-chart/values.yaml:"
echo "  image.repository: ${IMAGE}"
echo "  image.tag: \"${TAG}\""
echo "(or override at deploy time: helm template ... --set image.repository=${IMAGE} --set image.tag=${TAG})"
