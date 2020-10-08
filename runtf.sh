#! /bin/sh
# point to consul

distri=${DISTRIBUTION:-centos-7.7}
uuid=$(uuidgen)
uuid=${uuid%%-*}

terraform init
terraform $* -var ssh_password="$SSH_PASSWORD" -var vm_clone=t-${distri} -var vm_name=b-omd-${distri}-${uuid} -var cpu_sockets=2 -var cpu_cores=4 -var memory=32768 --auto-approve
