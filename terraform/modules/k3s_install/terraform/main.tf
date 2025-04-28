# Compute server IPs
locals {
  control_plane_plus_worker_ips = concat(var.control_plane_ips, var.worker_ips)
}
# Install prerequisistes
resource "ssh_resource" "install_prereqs" {
  triggers = {
    always_run = "${timestamp()}"
  }

  count = length(local.control_plane_plus_worker_ips)

  host         = local.control_plane_plus_worker_ips[count.index]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "apt update",
     "apt -y install curl",
  ]
}
# Install k3s on initial control plane node
resource "ssh_resource" "install_k3s_server" {
  triggers = {
    always_run = "${timestamp()}"
  }

  host         = var.control_plane_ips[0]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "curl -sfL https://get.k3s.io | sh -s - server --cluster-init --tls-san ${var.kube_api_loadbalancer_dns_name}"
  ]
  depends_on = [ ssh_resource.install_prereqs ]
}
# Get k3s server token, used to join other nodes to the cluster
resource "ssh_resource" "get_server_node_token" {
  triggers = {
    always_run = "${timestamp()}"
  }

  host         = var.control_plane_ips[0]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "cat /var/lib/rancher/k3s/server/token"
  ]
  depends_on = [ ssh_resource.install_k3s_server ]
}
# Compute other required values
locals {
  raw_server_node_token = sensitive(ssh_resource.get_server_node_token.result)
  server_node_token = regex(".*::server:.*", local.raw_server_node_token)
  other_control_plane_server_ips = slice(var.control_plane_ips, 1, length(var.control_plane_ips))
}
# Install and join other control plane nodes to the cluster
resource "ssh_resource" "install_k3s_control_plane" {
  triggers = {
    always_run = "${timestamp()}"
  }

  count = length(local.other_control_plane_server_ips)

  host         = local.other_control_plane_server_ips[count.index]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "curl -fL https://get.k3s.io | sh -s - server --token ${local.server_node_token} --cluster-init --server https://${var.control_plane_ips[0]}:6443 --tls-san ${var.kube_api_loadbalancer_dns_name}"
  ]
  depends_on = [ ssh_resource.install_k3s_server ]
}
# Install and join worker nodes
resource "ssh_resource" "install_k3s_worker" {
  triggers = {
    always_run = "${timestamp()}"
  }

  count = length(var.worker_ips)

  host         = var.worker_ips[count.index]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "curl -sfL https://get.k3s.io | K3S_URL=https://${var.control_plane_ips[0]}:6443 K3S_TOKEN=${local.server_node_token} sh -"
  ]
  depends_on = [ ssh_resource.install_k3s_control_plane ]
}
# Get kubeconfig
resource "ssh_resource" "get_kubeconfig" {
  triggers = {
    always_run = "${timestamp()}"
  }

  host         = var.control_plane_ips[0]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  commands = [
     "cat /etc/rancher/k3s/k3s.yaml"
  ]
  depends_on = [ ssh_resource.install_k3s_control_plane ]
}

# Outputs
output "ssh_resource_install_prereqs" {
  value = [for operation in ssh_resource.install_prereqs : operation.result]
}

output "ssh_resource_install_k3s_server" {
  value = ssh_resource.install_k3s_server.result
}

output "ssh_resource_install_k3s_control_plane" {
  value = [for operation in ssh_resource.install_k3s_control_plane : operation.result]
}

output "ssh_resource_install_k3s_worker" {
  value = [for operation in ssh_resource.install_k3s_worker : operation.result]
}

output "ssh_resource_get_kubeconfig" {
  value = ssh_resource.get_kubeconfig.result
  sensitive = true
}