# Global variables
variable "kubeconfig_file_path" {
  type    = string 
}
# Infra variables
variable "ssh_keys" {
  type = list(string)
  description = "List of SSH public keys"
}

variable "upcloud_k8s_zone" {
  type    = string
}

variable "upcloud_server_plan" {
  type    = string
}

variable "upcloud_server_OS" {
  type    = string
}

variable "environment" {
  type    = string
  default = "development"
}

variable "k8s_cluster_name" {
  type    = string
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
variable "ssh_pub_key_file_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_user" {
  type    = string 
  default = "root"
}
