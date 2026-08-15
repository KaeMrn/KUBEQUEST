provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------
# Network: reuse the lab-provided VPC/subnet unless explicitly overridden.
# ---------------------------------------------------------------------------

data "aws_vpc" "selected" {
  id      = var.vpc_id
  default = var.vpc_id == null ? true : null
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

locals {
  subnet_id = var.subnet_id != null ? var.subnet_id : data.aws_subnets.selected.ids[0]

  # Node name -> role. kube-1/kube-2 form the actual Kubernetes cluster;
  # node-3 and node-4 also join the cluster as workers but are labelled/tainted
  # (see infra/scripts/label-dedicated-nodes.sh) so the ingress-controller and
  # the monitoring stack are scheduled onto their own dedicated hardware, per
  # the project spec's "ingress" and "monitoring" node roles.
  nodes = {
    node-1 = { role = "control-plane", dedicated_for = null }
    node-2 = { role = "worker", dedicated_for = null }
    node-3 = { role = "worker", dedicated_for = "ingress" }
    node-4 = { role = "worker", dedicated_for = "monitoring" }
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Security group: SSH + Kubernetes control-plane/API + NodePort range +
# Flannel VXLAN overlay, all scoped to the VPC CIDR except SSH.
# ---------------------------------------------------------------------------

resource "aws_security_group" "kubequest" {
  name        = "kubequest-cluster"
  description = "KubeQuest Kubernetes cluster (control plane, workers, ingress, monitoring)"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    description = "kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    description = "NodePort services (ingress-nginx: 30080/30443)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flannel VXLAN overlay"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  ingress {
    description = "etcd (control plane only, but simplest as intra-VPC)"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "kubequest"
  }
}

# ---------------------------------------------------------------------------
# The 4 nodes
# ---------------------------------------------------------------------------

resource "aws_instance" "node" {
  for_each = local.nodes

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = local.subnet_id
  private_ip             = lookup(var.node_private_ips, each.key, null)
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.kubequest.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name         = each.key
    Project      = "kubequest"
    Role         = each.value.role
    DedicatedFor = each.value.dedicated_for
  }
}
