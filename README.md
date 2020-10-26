# docker-terraprox
Dockerfile, terraform + proxmox provider + sometimes patches

```bash
docker run --rm -it [--entrypoint /bin/sh]  lausser/terraprox (apply|destroy)
export PM_USER="packer@pve"
export PM_PASS="***"
export PM_API_URL="https://proxmox:8006/api2/json"
# the proxmox template
export DISTRIBUTION="centos-7.7"
# register ip address under nslookup/{vm_name}
export CONSUL_ADDRESS="consul-ui.infra-build"
# set password via cloud-init
export SSH_PASSWORD="***"

export VM_NAME="hostname inside, vm name outside"
# or alternatively "b-${product}-${distri}-${uuid}"
export PRODUCT="omd"
export UNIQUE_TAG="dnstest"

# either VM_NAME or DISTRIBUTION(mandatory)+PRODUCT(not yet mandatory)+UNIQUE_TAG
```

## Kubernetes

### Create a VM
This pod runs **terraform apply** and registers the ip address in a consul k/v store. The key is the vm_name.

```bash
kubectl -n dnstest apply -f create_vm.yml
# wait until vm is up
kubectl -n dnstest wait --for=condition=complete --timeout=24h job/create-vm
kubectl -n dnstest delete -f create_vm.yml
kubectl -n dnstest wait --for=delete --timeout=24h job/create-vm
```

### Use the VM
You can for example run an ansible container.
```bash
kubectl -n dnstest apply -f run_ansible.yml
kubectl -n dnstest wait --for=condition=complete --timeout=24h job/ansible

cat run_ansible.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ansible
data:
  runscript.sh: |
    #!/bin/bash
    vm_name=$1
    ip=$(curl "http://consul-ui.infra-build/v1/kv/nslookup/${vm_name}?dc=dc1&raw=1)
    # git clone all the needed ansible roles
    ...
```

### Destroy a VM
This pod just needs the same vm_name as the create-pod, then it will run **terraform destroy**.
```bash
kubectl -n dnstest apply -f destroy_vm.yml
kubectl -n dnstest wait --for=condition=complete --timeout=24h job/destroy-vm
kubectl -n dnstest delete -f destroy_vm.yml
kubectl -n dnstest wait --for=delete --timeout=24h job/destroy-vm
```


