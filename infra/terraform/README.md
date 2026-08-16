# Terraform — KubeQuest infrastructure

Provisions the 4 AWS EC2 instances described in `README.md`'s cluster architecture table:
`node-1` (control plane), `node-2` (worker), `node-3` (worker, dedicated to ingress-nginx),
`node-4` (worker, dedicated to the monitoring stack).

All 4 nodes join the same Kubernetes cluster. `node-3`/`node-4` are labelled and tainted
(see `../scripts/label-dedicated-nodes.sh`) so that ingress-controller and monitoring pods
are scheduled onto their own dedicated hardware, matching the project spec's "ingress" and
"monitoring" node roles without splitting the cluster in two.

## Usage

```bash
cd infra/terraform
terraform init
terraform plan -var="key_name=kubequest"
terraform apply -var="key_name=kubequest"
```

By default this reuses the AWS account's default VPC/subnet and the latest Amazon Linux 2023
AMI. Override `vpc_id`/`subnet_id` if the Epitech lab provides a dedicated VPC — check the
AWS console before applying.

## Outputs

```bash
terraform output ssh_commands
terraform output control_plane_private_ip
```

## Destroy

```bash
terraform destroy -var="key_name=kubequest"
```

The spec requires starting from a fresh cluster, so `terraform apply` after a
`terraform destroy` is the fast path to a clean environment — see
`../../scripts/bootstrap-cluster.sh` for the kubeadm steps that follow provisioning.
