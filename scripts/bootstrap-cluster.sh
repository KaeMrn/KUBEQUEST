#!/usr/bin/env bash
# Bootstraps a fresh kubeadm cluster on Amazon Linux 2023, matching the
# project's "before presenting, start a fresh new Kubernetes cluster"
# defense-day requirement.
#
# Usage:
#   On EVERY node (node-1..node-4):
#     ./bootstrap-cluster.sh install-runtime
#
#   Then on node-1 (control plane) ONLY:
#     ./bootstrap-cluster.sh init
#     -> prints a `kubeadm join ...` command, copy it
#
#   Then on node-2, node-3, node-4:
#     ./bootstrap-cluster.sh join "<the kubeadm join command printed above>"
#
#   Then from your local machine (kubeconfig pulled from node-1):
#     ./label-dedicated-nodes.sh
#
set -euo pipefail

K8S_VERSION="1.31"
POD_CIDR="10.244.0.0/16" # matches Flannel's default

install_runtime() {
  sudo dnf update -y
  sudo dnf install -y containerd

  # Kernel/sysctl prerequisites
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter

  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
  sudo sysctl --system

  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
  sudo systemctl enable --now containerd

  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/repodata/repomd.xml.key
EOF
  sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
  sudo systemctl enable --now kubelet

  sudo swapoff -a
  echo "Runtime installed. Ready for 'init' (node-1) or 'join' (node-2..4)."
}

init_control_plane() {
  ADVERTISE_IP="$(hostname -I | awk '{print $1}')"
  sudo kubeadm init \
    --apiserver-advertise-address="${ADVERTISE_IP}" \
    --pod-network-cidr="${POD_CIDR}"

  mkdir -p "$HOME/.kube"
  sudo cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
  sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

  kubectl apply -k "$(dirname "$0")/../cluster/flannel"

  echo
  echo "Control plane ready. Join the other 3 nodes with:"
  kubeadm token create --print-join-command
}

join_worker() {
  local join_cmd="$1"
  sudo bash -c "${join_cmd}"
}

case "${1:-}" in
  install-runtime) install_runtime ;;
  init) init_control_plane ;;
  join) join_worker "${2:?usage: bootstrap-cluster.sh join \"<kubeadm join ...>\"}" ;;
  *)
    echo "usage: $0 {install-runtime|init|join \"<kubeadm join command>\"}"
    exit 1
    ;;
esac
