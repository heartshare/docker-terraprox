#! /bin/sh
# point to consul

distri=${DISTRIBUTION:-centos-7.7}
if [ -z "$UNIQUE_TAG" ]; then
  uuid=$(uuidgen)
  uuid=${uuid%%-*}
else
  uuid=${UNIQUE_TAG}
fi

if [ -n "$CONSUL_ADDRESS" ]; then
  cat > backend.tf <<EOTF
terraform {
  backend "consul" {
    address = "${CONSUL_ADDRESS}"
    scheme  = "http"
    path    = "build/${distri}/${uuid}"
  }
}
EOTF
  cat > consul_node.tf <<EOTF
provider "consul" {
  address    = "${CONSUL_ADDRESS}"
  #datacenter = "nyc1"
}

resource "consul_keys" "nslookup" {
  key {
    name   = "address"
    path   = "nslookup/\${var.vm_uuid}"
    value  = proxmox_vm_qemu.cloudinit-vm.ssh_host
    delete = true
  }
}

resource "consul_node" "hostname" {
  name    = var.vm_uuid
  address = proxmox_vm_qemu.cloudinit-vm.ssh_host
}

EOTF
fi
terraform init
terraform $* -var ssh_password="$SSH_PASSWORD" -var vm_clone=t-${distri} -var vm_name=b-omd-${distri}-${uuid} -var cpu_sockets=2 -var cpu_cores=4 -var memory=32768 --auto-approve
