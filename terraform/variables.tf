# Global variables
variable "infrastructure_provider" {
  type    = string 
}

variable "kubeconfig_file_path" {
  type    = string 
}
# Infra Upcloud variables
## SSH
variable "ssh_keys" {
  type = list(string)
  description = "List of SSH public keys"
}
## Proxmox
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_cloudinit_template_name" {
  type = string
}

# Cluster variables
variable "proxmox_k8s_network_subnet_mask" {
  type    = string
  default = "24"
}
variable "proxmox_k8s_network_gateway" {
  type    = string
}

variable "proxmox_k8s_network_dns" {
  type    = string
}

variable "kube_vip_address" {
  type    = string
}
variable "proxmox_vm_plan" {
  type = map(string)
  default = {
    "cpu": "host"
    "cores": 2
    "memory": 4094
    "disk": "40G"
  }
}

variable "proxmox_vm_storage" {
  type    = string
}

variable "proxmox_vm_network_bridge" {
  type    = string
  default = "vmbr0"
}



## Upcloud
variable "upcloud_k8s_zone" {
  type    = string
}

variable "upcloud_server_plan" {
  type    = string
}

variable "upcloud_server_OS" {
  type    = string
}
## Cluster
variable "environment" {
  type    = string
  default = "development"
}

variable "k8s_cluster_name" {
  type    = string
}

variable "k8s_cluster_network_name" {
  type    = string
  default = ""
}

variable "k8s_cluster_network_subnet" {
  type    = string
}

variable "k8s_cluster_network_ip_address_family" {
  type    = string
  default = "IPv4"
}

variable "k8s_cluster_network_dhcp" {
  type    = bool
  default = true
}

variable "control_plane_public_network_interface" {
  type    = bool
  default = true
}

variable "control_plane_utility_network_interface" {
  type    = bool
  default = true
}

variable "worker_public_network_interface" {
  type    = bool
  default = true
}

variable "worker_utility_network_interface" {
  type    = bool
  default = true
}

variable "k8s_loadbalancer_extra_backends" {
  type = list(object({
    name = string
    backend_port = string
  })
  )

  default = []
}

variable "k8s_loadbalancer_extra_frontends" {
  type = list(object({
    name = string
    frontend_port = string
    frontend_protocol = string
    default_backend = string
  })
  )

  default = []
}


variable "control_plane_count" {
  type    = number
  default = 1

  validation {
    condition     = var.control_plane_count % 2 == 1
    error_message = "Cannot have an even number of etcd nodes."
  }
}

variable "worker_count" {
  type    = number
  default = 1
}

# K3s_install variables
## SSH
variable "ssh_pub_key_file_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_user" {
  type    = string 
  default = "root"
}


variable "kube_api_server_port" {
  type    = string
  default = "6443"
}

variable "kube_vip_enable" {
  type    = bool
  default = false
}

variable "kube_vip_interface" {
  type    = string
  default = "eth0"
}