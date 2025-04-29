## SSH
variable "ssh_keys" {
  type = list(string)
  description = "List of SSH public keys"
  sensitive = true
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "environment" {
  type    = string
  default = "development"
}

variable "proxmox_cloudinit_template_name" {
  type = string
}

# Cluster variables
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

variable "k8s_cluster_name" {
  type    = string
}

variable "k8s_cluster_network_subnet" {
  type    = string
}

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