# Deploy infrastructure
module "infra_upcloud" {
  count = var.infrastructure_provider == "upcloud" ? 1 : 0
  source = "./modules/infra/providers/upcloud/terraform"
  ssh_keys = var.ssh_keys
  control_plane_count = var.control_plane_count
  worker_count = var.worker_count
  k8s_cluster_name = var.k8s_cluster_name
  k8s_cluster_network_subnet = var.k8s_cluster_network_subnet
  k8s_loadbalancer_extra_backends = var.k8s_loadbalancer_extra_backends
  k8s_loadbalancer_extra_frontends = var.k8s_loadbalancer_extra_frontends
  upcloud_k8s_zone = var.upcloud_k8s_zone
  upcloud_server_plan = var.upcloud_server_plan
  upcloud_server_OS = var.upcloud_server_OS
}

module "infra_proxmox" {
  count = var.infrastructure_provider == "proxmox" ? 1 : 0
  source = "./modules/infra/providers/proxmox/terraform"
  providers = {
    proxmox = proxmox.dev
  }
  control_plane_count = var.control_plane_count
  worker_count = var.worker_count
  k8s_cluster_name = var.k8s_cluster_name
  k8s_cluster_network_subnet = var.k8s_cluster_network_subnet
  proxmox_api_url = var.proxmox_api_url
  proxmox_node = var.proxmox_node
  proxmox_cloudinit_template_name = var.proxmox_cloudinit_template_name
  proxmox_vm_storage = var.proxmox_vm_storage
  proxmox_vm_network_bridge = var.proxmox_vm_network_bridge
  proxmox_k8s_network_gateway = var.proxmox_k8s_network_gateway
  proxmox_k8s_network_dns = var.proxmox_k8s_network_dns
  kube_vip_address = var.kube_vip_address
  ssh_keys = var.ssh_keys
}

locals {
    infra_outputs = concat(module.infra_upcloud, module.infra_proxmox)
    control_plane_ips = local.infra_outputs[0].k8s_control_plane_ips
    worker_ips = local.infra_outputs[0].k8s_worker_ips
    control_plane_private_ips = local.infra_outputs[0].k8s_control_plane_private_ips
    worker_private_ips = local.infra_outputs[0].k8s_worker_private_ips
    kube_api_loadbalancer_dns_name = local.infra_outputs[0].kube_api_loadbalancer_dns_name
}

# Install kubernetes
module "k3s_install" {
  depends_on = [ module.infra_upcloud ]
  source = "./modules/k3s_install/terraform"
  ssh_user = var.ssh_user
  ssh_pub_key_file_path = var.ssh_pub_key_file_path
  control_plane_ips = local.control_plane_ips
  worker_ips = local.worker_ips
  kube_api_loadbalancer_dns_name = local.kube_api_loadbalancer_dns_name
  kube_vip_enable = var.kube_vip_enable
  kube_api_server_port = var.kube_api_server_port
  kube_vip_interface = var.kube_vip_interface
  kube_vip_address = var.kube_vip_address
}

locals {
  install_k3s_server_output = module.k3s_install.ssh_resource_install_k3s_server
  install_k3s_control_plane_output = module.k3s_install.ssh_resource_install_k3s_control_plane
  install_k3s_worker_output = module.k3s_install.ssh_resource_install_k3s_worker
  kubeconfig = module.k3s_install.ssh_resource_get_kubeconfig
}

# Outputs
output "install_k3s_server_output" {
  value = local.install_k3s_server_output
}

output "install_k3s_control_plane_output" {
  value = local.install_k3s_control_plane_output
}

output "install_k3s_worker_output" {
  value = local.install_k3s_worker_output
}

resource "local_sensitive_file" "kubeconfig" {
  content  = replace(local.kubeconfig, "127.0.0.1", local.kube_api_loadbalancer_dns_name)
  filename = var.kubeconfig_file_path
}
# Install default apps
module "apps_install" {
  depends_on = [ module.k3s_install ]
  source = "./modules/apps/terraform"
  ssh_user = var.ssh_user
  ssh_pub_key_file_path = var.ssh_pub_key_file_path
  control_plane_ips = local.control_plane_ips
}
