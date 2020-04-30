FROM hashicorp/terraform

RUN apk add --no-cache make musl-dev go rsync shadow python3
RUN apk add --no-cache bash python3-dev
RUN apk add --no-cache patch
RUN apk add --no-cache ansible
RUN pip3 install ruamel.yaml
RUN groupadd -r terraform -g 9901 && useradd -u 9901 --no-log-init -m -r -g terraform terraform

WORKDIR /root
# the lausser fork contains a patch which copies a cloud-init's dhcp
# address to self.ssh_host
RUN go get github.com/lausser/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox

RUN go get github.com/Telmate/proxmox-api-go && \
    go install github.com/Telmate/proxmox-api-go && \
    cp go/bin/proxmox-api-go /usr/local/bin

RUN go get github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox
RUN cp go/src/github.com/lausser/terraform-provider-proxmox/proxmox/resource_vm_qemu.go go/src/github.com/Telmate/terraform-provider-proxmox/proxmox
RUN go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox && \
    cp go/bin/terraform-provider-proxmox /usr/local/bin

RUN go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox && \
    cp go/bin/terraform-provisioner-proxmox /usr/local/bin

USER terraform
WORKDIR /home/terraform

RUN  mkdir /home/terraform/.ssh && \
    chmod 700 /home/terraform/.ssh && \
    ssh-keygen -f /home/terraform/.ssh/id_rsa -N ""
RUN mkdir -p /home/terraform/.terraform.d/plugins/linux_amd64 && \
    cp /usr/local/bin/terraform-provider-proxmox  /home/terraform/.terraform.d/plugins/linux_amd64/ && \
    cp /usr/local/bin/terraform-provisioner-proxmox  /home/terraform/.terraform.d/plugins/linux_amd64/

USER root
COPY runtf.sh /home/terraform
RUN chown terraform:terraform /home/terraform/runtf.sh
RUN chmod 755 /home/terraform/runtf.sh

USER terraform
ENTRYPOINT ["/home/terraform/runtf.sh"]
