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

variable "disk_size" {
    type = string
    # 32 from proxmox-packer. must not be smaller than the template's disk size
    default = "32G"
}

variable "disk_cache" {
    type = string
    default = "none"
}

variable "ansible_playbook" {
    type = string
    default = "none"
}
