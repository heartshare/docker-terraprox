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

variable "cpu_cores" {
    type = number
    default = 4
}

variable "cpu_sockets" {
    type = number
    default = 1
}

variable "memory" {
    type = number
    default = 16384
}

variable "disk_storage" {
    type = string
    default = "ceph01"
}

variable "disk_storage_type" {
    type = string
    default = "rbd"
}

variable "disk_size" {
    type = number
    default = 4
}

variable "disk_cache" {
    type = string
    default = "none"
}

variable "ansible_playbook" {
    type = string
    default = "none"
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

  cores = var.cpu_cores
  sockets = var.cpu_sockets
  memory = var.memory

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
    storage = var.disk_storage
    storage_type = var.disk_storage_type
    size = var.disk_size
    backup = false
    iothread = true
    #cache = var.disk_cache
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
  provisioner "local-exec" {
    command =<<EOCMD
    printf "[defaults]\nhost_key_checking = False\n" > ~/.ansible.cfg
    ansible -m ping -i ${self.ssh_host}, -u packer --extra-vars ansible_ssh_pass=${var.ssh_password} all
    EOCMD
  }
#  provisioner "local-exec" {
#    command =<<EOCMD
#    if [ "${var.ansible_playbook}" != "" ]; then
#      ansible-playbook ansible/playbooks/${var.ansible_playbook} -i ${self.ssh_host}, -u packer --extra-vars ansible_ssh_pass=${var.ssh_password}
#    fi
#    EOCMD
#  }
}
