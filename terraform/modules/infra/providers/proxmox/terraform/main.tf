resource "proxmox_vm_qemu" "k8s_control_plane" {
  count = var.control_plane_count
  name = "${var.k8s_cluster_name}-control-plane-${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.proxmox_cloudinit_template_name
  agent = 1
  os_type = "cloud-init"
  cores = var.proxmox_vm_plan["cores"]
  sockets = 1
  cpu = "host"
  memory = var.proxmox_vm_plan["memory"]
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"


  disk {
    slot = 0
    size = var.proxmox_vm_plan["disk"]
    type = "scsi"
    storage = var.proxmox_vm_storage
    ssd = 1
  }

  network {
    model = "virtio"
    bridge = var.proxmox_vm_network_bridge
  }
  

  lifecycle {
    ignore_changes = [
      network, tags, qemu_os
    ]
  }

  tags = "env_${var.environment},project_${var.k8s_cluster_name},k8s_role_control-plane"

  ipconfig0 = "ip=${cidrhost(var.k8s_cluster_network_subnet, count.index)}/${var.proxmox_k8s_network_subnet_mask},gw=${var.proxmox_k8s_network_gateway}"
  nameserver = var.proxmox_k8s_network_dns
  sshkeys = <<EOF
  ${var.ssh_keys[0]}
  EOF
}


resource "proxmox_vm_qemu" "k8s_worker" {
  count = var.worker_count
  name = "${var.k8s_cluster_name}-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.proxmox_cloudinit_template_name
  agent = 1
  os_type = "cloud-init"
  cores = var.proxmox_vm_plan["cores"]
  sockets = 1
  cpu = "host"
  memory = var.proxmox_vm_plan["memory"]
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"


  disk {
    slot = 0
    size = var.proxmox_vm_plan["disk"]
    type = "scsi"
    storage = var.proxmox_vm_storage
    ssd = 1
  }

  network {
    model = "virtio"
    bridge = var.proxmox_vm_network_bridge
  }
  

  lifecycle {
    ignore_changes = [
      network, tags, qemu_os
    ]
  }

  tags = "env_${var.environment},project_${var.k8s_cluster_name},k8s_role_worker"

  ipconfig0 = "ip=${cidrhost(var.k8s_cluster_network_subnet, count.index+var.control_plane_count)}/${var.proxmox_k8s_network_subnet_mask},gw=${var.proxmox_k8s_network_gateway}"
  nameserver = var.proxmox_k8s_network_dns
  sshkeys = <<EOF
  ${var.ssh_keys[0]}
  EOF
}

output "k8s_control_plane_ips" {
  value = [ for server in proxmox_vm_qemu.k8s_control_plane : split("/", replace(server.ipconfig0, "ip=", ""))[0] ]
}

output "k8s_worker_ips" {
  value = [ for server in proxmox_vm_qemu.k8s_worker : split("/", replace(server.ipconfig0, "ip=", ""))[0] ]
}

output "k8s_control_plane_private_ips" {
  value = [ for server in proxmox_vm_qemu.k8s_control_plane : split("/", replace(server.ipconfig0, "ip=", ""))[0] ]
}

output "k8s_worker_private_ips" {
  value = [ for server in proxmox_vm_qemu.k8s_worker : split("/", replace(server.ipconfig0, "ip=", ""))[0] ]
}

output "kube_api_loadbalancer_dns_name" {
  value = var.kube_vip_address
}