# Global variables
variable "kubeconfig_file_path" {
  type    = string 
}
# Infra Upcloud variables
## SSH
variable "ssh_keys" {
  type = list(string)
  description = "List of SSH public keys"
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
  default = 3
}

variable "worker_count" {
  type    = number
  default = 2
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
