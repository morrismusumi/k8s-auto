# Deploy infrastructure
module "infra-upcloud" {
  source = "./modules/infra/providers/upcloud/terraform"
  ssh_keys = var.ssh_keys
  k8s_cluster_name = var.k8s_cluster_name
  upcloud_k8s_zone = var.upcloud_k8s_zone
  upcloud_server_plan = var.upcloud_server_plan
  upcloud_server_OS = var.upcloud_server_OS
}

locals {
    control_plane_ips = module.infra-upcloud.upcloud_server_k8s_control_plane_ips
    worker_ips = module.infra-upcloud.upcloud_server_k8s_worker_ips
    control_plane_private_ips = module.infra-upcloud.upcloud_control_plane_private_ips
    woker_private_ips = module.infra-upcloud.upcloud_woker_private_ips
    kube_api_loadbalancer_dns_name = module.infra-upcloud.upcloud_lb_dns_name
}
# Install kubernetes
module "k3s_install" {
  depends_on = [ module.infra-upcloud ]
  source = "./modules/k3s_install/terraform"
  ssh_user = var.ssh_user
  ssh_pub_key_file_path = var.ssh_pub_key_file_path
  control_plane_ips = local.control_plane_ips
  worker_ips = local.worker_ips
  kube_api_loadbalancer_dns_name = local.kube_api_loadbalancer_dns_name
}

locals {
  install_prereq_output = module.k3s_install.ssh_resource_install_prereqs
  install_k3s_server_output = module.k3s_install.ssh_resource_install_k3s_server
  install_k3s_control_plane_output = module.k3s_install.ssh_resource_install_k3s_control_plane
  install_k3s_worker_output = module.k3s_install.ssh_resource_install_k3s_worker
  kubeconfig = module.k3s_install.ssh_resource_get_kubeconfig
}

# Outputs
output "install_prereq_output" {
  value = local.install_prereq_output
}

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

