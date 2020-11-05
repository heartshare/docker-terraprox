#! /bin/sh
# point to consul

distri=${DISTRIBUTION:-centos-7.7}
product=${PRODUCT:-omd}
if [ -z "$UNIQUE_TAG" ]; then
  uuid=$(uuidgen)
  uuid=${uuid%%-*}
else
  uuid=${UNIQUE_TAG}
fi
if [ -z "$VM_NAME" ]; then
  vmname="b-${product}-${distri}-${uuid}"
else
  vmname=${VM_NAME}
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
  #datacenter = "dc1"
}

resource "consul_keys" "nslookup" {
  key {
    name   = "address"
    path   = "nslookup/\${var.vm_name}"
    value  = proxmox_vm_qemu.cloudinit-vm.ssh_host
    delete = true
  }
}

# can be used later for dns lookups, services
#resource "consul_node" "hostname" {
#  name    = var.vm_uuid
#  address = proxmox_vm_qemu.cloudinit-vm.ssh_host
#}
EOTF
fi

if [ "$1" == "apply" ]; then
  terraform init
  terraform apply -var ssh_password="$SSH_PASSWORD" -var vm_clone=t-${distri} -var vm_name=${vmname} -var cpu_sockets=2 -var cpu_cores=4 -var memory=32768 --auto-approve
elif [ "$1" == "destroy" ]; then
  terraform destroy --auto-approve
elif [[ "$1"  =~ state ]]; then
  terraform $1 --auto-approve
else
  echo unknown arg ${1:-empty-}
  exit 1
fi
