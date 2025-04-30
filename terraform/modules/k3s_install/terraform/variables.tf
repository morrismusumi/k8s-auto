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
  default = "k8s-auto"
}

variable "kube_api_server_port" {
  type    = string
  default = "6443"
}

variable "kube_vip_interface" {
  type    = string
  default = "eth0"
}

variable "kube_vip_enable" {
  type    = bool
  default = false
}


variable "kube_vip_address" {
  type    = string
}


