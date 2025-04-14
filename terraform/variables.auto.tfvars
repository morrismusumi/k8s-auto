# Global variables
k8s_cluster_name = "k3s-auto"
environment  = "development"
control_plane_count = 3
worker_count  = 2
kubeconfig_file_path = "~/.kubeconfig"
# K3s_install variables
ssh_pub_key_file_path = "~/.ssh/id_rsa"
ssh_user = "root"

# UpCloud variables
upcloud_k8s_zone  = "de-fra1"
upcloud_server_plan  = "2xCPU-4GB"
upcloud_server_OS = "Debian GNU/Linux 11 (Bullseye)"

# Proxmox variables