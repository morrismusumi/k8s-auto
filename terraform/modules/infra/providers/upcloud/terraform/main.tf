# Create cluster private network
resource "upcloud_network" "k8s_network" {
  name = "${var.k8s_cluster_name}-k8s-net"
  zone = var.upcloud_k8s_zone
  ip_network {
    address = "10.44.0.0/24"
    dhcp    = true
    family  = "IPv4"
  }
}
# Create control plane servers
resource "upcloud_server" "k8s_control_plane" {
  count = var.control_plane_count
  hostname = "${var.k8s_cluster_name}-control-plane-${var.upcloud_k8s_zone}-${count.index + 1}"
  zone     = var.upcloud_k8s_zone
  plan     = var.upcloud_server_plan

  template {
    storage = var.upcloud_server_OS
  }

  network_interface {
    type = "public"
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "utility"
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "private"
    network           = upcloud_network.k8s_network.id
  }

  labels = {
    env        = var.environment
    project    = var.k8s_cluster_name
    k8s_role   = "control-plane"
  }

  login {
    keys = var.ssh_keys
  }
}
# Create worker servers
resource "upcloud_server" "k8s_worker" {
  count = var.worker_count
  hostname = "${var.k8s_cluster_name}-worker-${var.upcloud_k8s_zone}-${count.index + 1}"
  zone     = var.upcloud_k8s_zone
  plan     = var.upcloud_server_plan

  template {
    storage = var.upcloud_server_OS
  }

  network_interface {
    type = "public"
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "utility"
  }

  network_interface {
    ip_address_family = "IPv4"
    type              = "private"
    network           = upcloud_network.k8s_network.id
  }

  labels = {
    env        = var.environment
    project    = var.k8s_cluster_name
    k8s_role   = "worker"
  }

  login {
    keys = var.ssh_keys
  }
}
# Create load balancer
resource "upcloud_loadbalancer" "k8s_lb" {
  configured_status = "started"
  name              = "${var.k8s_cluster_name}-k8s-lb"
  plan              = "development"
  zone              = var.upcloud_k8s_zone
  networks {
    name    = "Private-Net"
    type    = "private"
    family  = "IPv4"
    network = resource.upcloud_network.k8s_network.id
  }
  networks {
    name   = "Public-Net"
    type   = "public"
    family = "IPv4"
  }
}
# Create backend for kubeapi server
resource "upcloud_loadbalancer_backend" "lb_be_kube_api" {
  loadbalancer      = resource.upcloud_loadbalancer.k8s_lb.id
  name              = "kube-api"
}
# Compute values required by next resources, and outputs 
locals {
  control_plane_private_ips = [
    for server in upcloud_server.k8s_control_plane : server.network_interface[2].ip_address
  ]

  worker_private_ips = [
    for server in upcloud_server.k8s_worker : server.network_interface[2].ip_address
  ]

  control_plane_plus_worker_private_ips = concat(local.control_plane_private_ips, local.worker_private_ips)

  lb_dns_name = [
    for network in upcloud_loadbalancer.k8s_lb.networks : network.dns_name
    if network.type == "public"
  ][0]

}
# Add control plane servers as memebers to kubeapi server backend
resource "upcloud_loadbalancer_static_backend_member" "lb_be_static_member_kube_api" {
  count = length(local.control_plane_private_ips)
  backend      = resource.upcloud_loadbalancer_backend.lb_be_kube_api.id
  name         = "member_kube_api-${count.index + 1}"
  ip           = local.control_plane_private_ips[count.index]
  port         = 6443
  weight       = 0
  max_sessions = 0
  enabled      = true
}
# Create front end for kubeapi server backend 
resource "upcloud_loadbalancer_frontend" "lb_fe_kube_api" {
  loadbalancer         = resource.upcloud_loadbalancer.k8s_lb.id
  name                 = "kube-api"
  mode                 = "http"
  port                 = 6443
  default_backend_name = resource.upcloud_loadbalancer_backend.lb_be_kube_api.name
  networks {
    name = resource.upcloud_loadbalancer.k8s_lb.networks[1].name
  }
}
# Create traefik ingress backend
resource "upcloud_loadbalancer_backend" "lb_be_traefik" {
  loadbalancer      = resource.upcloud_loadbalancer.k8s_lb.id
  name              = "traefik"
}
# Add all clluster servers as memebers to traefik ingress backend
resource "upcloud_loadbalancer_static_backend_member" "lb_be_static_member_traefik" {
  count = length(local.control_plane_plus_worker_private_ips)
  backend      = resource.upcloud_loadbalancer_backend.lb_be_traefik.id
  name         = "member_traefik-${count.index + 1}"
  ip           = local.control_plane_plus_worker_private_ips[count.index]
  port         = 31100
  weight       = 0
  max_sessions = 0
  enabled      = true
}
# Create frontend for traefik ingress backend
resource "upcloud_loadbalancer_frontend" "lb_fe_traefik" {
  loadbalancer         = resource.upcloud_loadbalancer.k8s_lb.id
  name                 = "traefik"
  mode                 = "http"
  port                 = 80
  default_backend_name = resource.upcloud_loadbalancer_backend.lb_be_traefik.name
  networks {
    name = resource.upcloud_loadbalancer.k8s_lb.networks[1].name
  }
}

# Outputs
output "upcloud_server_k8s_control_plane_ips" {
  value = [for server in upcloud_server.k8s_control_plane : server.network_interface[0].ip_address]
}

output "upcloud_server_k8s_worker_ips" {
  value = [for server in upcloud_server.k8s_worker : server.network_interface[0].ip_address]
}

output "upcloud_control_plane_private_ips" {
  value = local.control_plane_private_ips
}

output "upcloud_woker_private_ips" {
  value = local.worker_private_ips
}

output "upcloud_lb_dns_name" {
  value = local.lb_dns_name
}