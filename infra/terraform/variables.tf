variable "aws_region" {
  description = "AWS region for the cluster (matches existing deployment: Ireland)"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC provided by the Epitech AWS lab. Leave null to use the account's default VPC."
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet to launch the 4 instances into. Leave null to auto-pick the first default subnet in the region."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Name of the EC2 key pair (matches kubequest.pem already used to SSH into the nodes)"
  type        = string
  default     = "kubequest"
}

variable "instance_type" {
  description = "Instance size for all 4 nodes"
  type        = string
  default     = "t3.medium"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the nodes. Restrict this to your own IP/32 in production."
  type        = string
  default     = "0.0.0.0/0"
}

# Private IPs pinned to match the ones already documented in README.md.
# If you re-provision from scratch and don't care about matching the old
# addressing, delete the `private_ip` argument in main.tf instead of using this map.
variable "node_private_ips" {
  description = "Static private IPs per node, matching the existing cluster documented in README.md"
  type        = map(string)
  default = {
    node-1 = "10.1.35.10"
    node-2 = "10.1.35.52"
    node-3 = "10.1.35.197"
    node-4 = "10.1.35.124"
  }
}
