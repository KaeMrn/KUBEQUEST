output "node_public_ips" {
  description = "Public IP per node, for SSH"
  value       = { for k, v in aws_instance.node : k => v.public_ip }
}

output "node_private_ips" {
  description = "Private IP per node, for the kubeadm join / /etc/hosts entries"
  value       = { for k, v in aws_instance.node : k => v.private_ip }
}

output "control_plane_private_ip" {
  description = "Private IP of node-1, used as --apiserver-advertise-address in kubeadm init"
  value       = aws_instance.node["node-1"].private_ip
}

output "ssh_commands" {
  description = "Ready-to-run SSH commands for each node"
  value = {
    for k, v in aws_instance.node :
    k => "ssh -i kubequest.pem ec2-user@${v.public_ip}"
  }
}
