variable "ssh_pub_key_file_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "control_plane_ips" {
  type    = list(string)
}

variable "worker_ips" {
  type    = list(string)
}

variable "ssh_user" {
  type    = string 
  default = "root"
}

variable "kube_api_loadbalancer_dns_name" {
  type    = string
}