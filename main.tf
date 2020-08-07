provider "proxmox" {
    pm_tls_insecure = true
}

variable "ssh_password" {
    type = string
    default = "geheim"
}

variable "target_node" {
    type = string
    default = "vm02"
}

variable "vm_name" {
    type = string
    default = "myvm"
}

variable "vm_clone" {
    type = string
    default = "t-centos-7.7"
}

variable "target_pool" {
    type = string
    default = "infra"
}

data "local_file" "private_key" {
        filename = "${path.module}/id_rsa"
}

data "local_file" "public_key" {
        filename = "${path.module}/id_rsa.pub"
}

resource "proxmox_vm_qemu" "cloudinit-vm" {
  name = var.vm_name
  desc = "qemu vm started with cloud-init"
  target_node = var.target_node
  clone = var.vm_clone
  full_clone = false
  agent = 1

  os_type = "cloud-init"
  ipconfig0 = "ip=dhcp"

  # The destination resource pool for the new VM
  pool = var.target_pool

  cores = 4
  sockets = 1
  memory = 16384

  vga {
    type = "std"
    memory = 4
  }

  network {
    id = 0
    bridge = "vmbr0"
    model = "virtio"
  }

  disk {
    id = 0
    type = "virtio"
    storage = "ceph01"
    storage_type = "rbd"
    size = 4
    backup = false
    iothread = true
  }

  connection {
    user = "packer"
    password = var.ssh_password
    host = self.ssh_host
    # has preference over the password
#    private_key = data.local_file.private_key.content
  }
  provisioner "remote-exec" {
    inline = [
      "/sbin/ip a"
    ]
  }
}
