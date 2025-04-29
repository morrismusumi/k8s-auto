# Install traefik
resource "ssh_resource" "install_traefik" {
  triggers = {
    always_run = "${timestamp()}"
  }

  host         = var.control_plane_ips[0]
  user         = var.ssh_user
  private_key  = file("${var.ssh_pub_key_file_path}")

  file {
    source      = "${path.module}/manifests/traefik.yaml"
    destination = "/tmp/traefik.yaml"
    permissions = "0700"
  }

  commands = [
     "sudo mv /tmp/traefik.yaml /var/lib/rancher/k3s/server/manifests/traefik.yaml",
  ]
}
# # Install cert-manager
# resource "ssh_resource" "install_cert_manager" {
#   triggers = {
#     always_run = "${timestamp()}"
#   }

#   host         = var.control_plane_ips[0]
#   user         = var.ssh_user
#   private_key  = file("${var.ssh_pub_key_file_path}")

#   file {
#     source      = "${path.module}/manifests/cert-manager.yaml"
#     destination = "/var/lib/rancher/k3s/server/manifests/cert-manager.yaml"
#     permissions = "0700"
#   }

#   commands = [
#      "ls -l /var/lib/rancher/k3s/server/manifests/",
#   ]
# }