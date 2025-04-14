variable "ssh_pub_key_file_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

variable "control_plane_ips" {
  type    = list(string)
}

variable "ssh_user" {
  type    = string 
  default = "root"
}