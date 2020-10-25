# docker-terraprox
Dockerfile, terraform + proxmox provider + sometimes patches

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


```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scripts
#  namespace: testxy
data:
  runscript.sh: |
    #!/bin/bash
    echo args $*
    sleep 10
    bash -x ./entrypoint.sh $*
    #sleep 100000
---
apiVersion: v1
kind: Pod
metadata:
  name: create-vm
#  namespace: testxy
spec:
  restartPolicy: Never
  containers:
    - name: terraform-apply
      image: lausser/terraprox:1.0
      # for debugging. later jump to entrypoint.sh dorectly
      command: [ "/scripts/runscript.sh" ]
      args: ["apply"]
      volumeMounts:
        - name: scripts
          mountPath: /scripts
      env:
        - name: PM_USER
          value: "packer@pve"
        - name: PM_PASS
          value: "***"
        - name: PM_API_URL
          value: "https://proxmox:8006/api2/json"
        - name: PRODUCT
          value: "omd"
        - name: DISTRIBUTION
          value: "centos-7.7"
        - name: SSH_PASSWORD
          value: "***"
        - name: CONSUL_ADDRESS
          value: "consul-ui.infra-build"
        - name: UNIQUE_TAG
          value: "abcxyz"
  volumes:
  - name: scripts
    configMap:
      name: scripts
      defaultMode: 0755
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scripts
#  namespace: testxy
data:
  runscript.sh: |
    #!/bin/bash
    echo args $*
    bash -x ./entrypoint.sh $*
    #sleep 100000
---
apiVersion: v1
kind: Pod
metadata:
  name: destroy-vm
#  namespace: testxy
spec:
  restartPolicy: Never
  containers:
    - name: terraform-apply
      image: lausser/terraprox:1.0
      command: [ "/scripts/runscript.sh" ]
      args: ["destroy"]
      volumeMounts:
        - name: scripts
          mountPath: /scripts
      env:
        - name: PM_USER
          value: "packer@pve"
        - name: PM_PASS
          value: "***"
        - name: PM_API_URL
          value: "https://proxmox:8006/api2/json"
        - name: CONSUL_ADDRESS
          value: "consul-ui.infra-build"
        - name: UNIQUE_TAG
          value: "abcxyz"
  volumes:
  - name: scripts
    configMap:
      name: scripts
      defaultMode: 0755
```
