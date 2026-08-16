#!/usr/bin/env bash
# Sideloads the locally-built app image onto every node (containerd).
# No registry needed: exports from the local Docker daemon and imports
# straight into containerd on each node.
#
# Usage: ./load-app-image-to-nodes.sh [image:tag]
# Prerequisites: terraform apply done, infra/kubequest.pem present,
#   nodes reachable via SSH (ec2-user).
set -euo pipefail

IMAGE="${1:-kubequest-app:v1}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEY="${ROOT_DIR}/infra/kubequest.pem"
TF_DIR="${ROOT_DIR}/infra/terraform"

if [[ ! -f "$KEY" ]]; then
  echo "Missing ${KEY}. Put the AWS key pair there (see infra/terraform/README.md)."
  exit 1
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image ${IMAGE} not found locally. Build it with:"
  echo "  scripts/build-and-push-app-image.sh kubequest-app v1 --local"
  exit 1
fi

IPS="$(terraform -chdir="${TF_DIR}" output -json node_public_ips \
  | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin).values()))')"
if [[ -z "${IPS}" ]]; then
  echo "No node public IPs from terraform output. Run terraform apply first."
  exit 1
fi

TMP="$(mktemp /tmp/kubequest-app-XXXXXX.tar)"
trap 'rm -f "$TMP"' EXIT
echo "Saving ${IMAGE}..."
docker save -o "$TMP" "$IMAGE"

for ip in ${IPS}; do
  echo "== Loading ${IMAGE} onto ${ip} =="
  scp -i "$KEY" -o StrictHostKeyChecking=accept-new "$TMP" "ec2-user@${ip}:/tmp/kubequest-app.tar"
  ssh -i "$KEY" -o StrictHostKeyChecking=accept-new "ec2-user@${ip}" \
    "sudo ctr -n k8s.io images import /tmp/kubequest-app.tar && rm -f /tmp/kubequest-app.tar"
done

echo "Image loaded on all nodes."
