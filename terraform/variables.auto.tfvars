# Global variables

# Infra_upcloud Variables

# UpCloud variables
upcloud_k8s_zone  = "de-fra1"
upcloud_server_plan  = "2xCPU-4GB"
upcloud_server_OS = "Debian GNU/Linux 11 (Bullseye)"
## Cluster
k8s_cluster_name = "k3s-auto"
k8s_cluster_network_subnet = "10.1.0.0/24"
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
ssh_user = "root"



# Proxmox variables