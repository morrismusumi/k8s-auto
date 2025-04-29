# Compute server IPs
locals {
  control_plane_plus_worker_ips = concat(var.control_plane_ips, var.worker_ips)
}
# Install prerequisistes
resource "terraform_data" "install_prereqs" {
  count = length(local.control_plane_plus_worker_ips)

  input = {
    ip         = local.control_plane_plus_worker_ips[count.index]
    user       = var.ssh_user
    private_key = sensitive(file("${var.ssh_pub_key_file_path}"))
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        #!/bin/bash

        echo "Detecting package manager..."
        if command -v apt-get >/dev/null 2>&1; then
          echo "APT-based system detected"

          timeout=300
          elapsed=0

          while lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
                lsof /var/lib/dpkg/lock >/dev/null 2>&1 || \
                lsof /var/lib/apt/lists/lock >/dev/null 2>&1 || \
                lsof /var/cache/apt/archives/lock >/dev/null 2>&1
          do
            if [ "$elapsed" -ge "$timeout" ]; then
              echo "Timeout waiting for apt lock!"
              exit 1
            fi
            echo "Waiting for apt lock... elapsed:" $elapsed
            sleep 2
            elapsed=$((elapsed + 2))
          done

          echo "Installing packages with apt..."
          sudo apt-get update -y
          sudo apt-get install -y curl gettext

        elif command -v dnf >/dev/null 2>&1; then
          echo "DNF-based system detected"

          timeout=300
          elapsed=0

          while fuser /var/cache/dnf/metadata_lock.pid >/dev/null 2>&1
          do
            if [ "$elapsed" -ge "$timeout" ]; then
              echo "Timeout waiting for dnf lock!"
              exit 1
            fi
            echo "Waiting for dnf lock... elapsed:" $elapsed
            sleep 2
            elapsed=$((elapsed + 2))
          done

          echo "Installing packages with dnf..."
          sudo dnf install -y curl gettext

        else
          echo "No supported package manager found."
          exit 1
        fi
      EOT
    ]

    connection {
      type        = "ssh"
      host        = self.input.ip
      user        = self.input.user
      private_key = self.input.private_key
    }
  }
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
  depends_on = [ terraform_data.install_prereqs ]
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
     "sudo cat /var/lib/rancher/k3s/server/token"
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
     "sudo cat /etc/rancher/k3s/k3s.yaml"
  ]
  depends_on = [ ssh_resource.install_k3s_server ]
}


# Install kube-vip
resource "ssh_resource" "kube-vip" {
  count    = var.kube_vip_enable ? 1 : 0
  triggers = {
    always_run = "${timestamp()}"
  }

  host         = var.control_plane_ips[0]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  file {
    source      = "${path.module}/manifests/kube-vip-rbac.yaml"
    destination = "/tmp/kube-vip-rbac.yaml"
    permissions = "0700"
  }

  file {
    source      = "${path.module}/manifests/kube-vip.yaml"
    destination = "/tmp/kube-vip.yaml"
    permissions = "0700"
  }
  
  commands = [
     "sudo mv /tmp/kube-vip-rbac.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml",
     "echo 'KUBE_API_VIP=${var.kube_vip_address}' >> /tmp/.env",
     "echo 'KUBE_API_SERVER_PORT=${var.kube_api_server_port}' >> /tmp/.env",
     "echo 'KUBE_VIP_INTERFACE=${var.kube_vip_interface}' >> /tmp/.env",
     "set -a; source /tmp/.env; set +a; envsubst < /tmp/kube-vip.yaml | sudo tee /var/lib/rancher/k3s/server/manifests/kube-vip.yaml > /dev/null",
     "rm -rf /tmp/.env"
  ]

  depends_on = [ ssh_resource.install_k3s_server ]
}

# Outputs
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