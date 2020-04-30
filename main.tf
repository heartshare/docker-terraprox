provider "proxmox" {
    pm_tls_insecure = true
}

variable "ssh_password" {
    type = string
    default = "geheim"
}

data "local_file" "private_key" {
        filename = "/home/terraform/.ssh/id_rsa"
}

data "local_file" "public_key" {
        filename = "/home/terraform/.ssh/id_rsa.pub"
}

resource "proxmox_vm_qemu" "cloudinit-vm" {
  name = "myvm"
  desc = "qemu vm started with cloud-init"
  target_node = "vm01"
  clone = "t-centos-7.7"
  full_clone = false
  agent = 1

  os_type = "cloud-init"
  ipconfig0 = "ip=dhcp"

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
  }
  provisioner "remote-exec" {
    inline = [
      "/sbin/ip a"
    ]
  }
}

