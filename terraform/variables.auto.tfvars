# Global variables
infrastructure_provider = "proxmox"
# Infra_upcloud Variables

# UpCloud variables
upcloud_k8s_zone  = "de-fra1"
upcloud_server_plan  = "2xCPU-4GB"
upcloud_server_OS = "Debian GNU/Linux 11 (Bullseye)"
## Cluster
k8s_cluster_name = "k3s-auto"
k8s_cluster_network_subnet = "172.30.0.16/28"
environment  = "development"
control_plane_count = 1
worker_count  = 1

k8s_loadbalancer_extra_backends = [{
  backend_port = "31100"
  name = "traefik-ingress"
}
]

k8s_loadbalancer_extra_frontends = [{
  default_backend = "traefik-ingress"
  frontend_port = "80"
  frontend_protocol = "tcp"
  name = "traefik-ingress"
}]

kubeconfig_file_path = "./kubeconfig"
# K3s_install variables
## SSH
ssh_pub_key_file_path = "~/.ssh/id_rsa"
ssh_user = "debian"



# Proxmox variables
proxmox_api_url = "https://192.168.0.200:8006/api2/json"

proxmox_node = "dc"
proxmox_cloudinit_template_name = "debian-11-cloudinit-template"
proxmox_vm_storage = "pve1"
proxmox_vm_network_bridge = "vmbr3"

proxmox_k8s_network_subnet_mask = "24"
proxmox_k8s_network_gateway = "172.30.0.1"
proxmox_k8s_network_dns = "172.20.0.31"
kube_vip_address = "172.30.0.15"
kube_vip_enable = true
kube_api_server_port = "6443"