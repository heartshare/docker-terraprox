FROM hashicorp/terraform

RUN apk add --no-cache make musl-dev go rsync shadow python3
RUN apk add --no-cache bash python3-dev
RUN apk add --no-cache patch
RUN apk add --no-cache ansible
RUN apk add --no-cache sshpass
RUN apk add --no-cache util-linux
RUN apk add --no-cache py3-pip
RUN pip3 install ruamel.yaml
RUN groupadd -r terraform -g 9901 && useradd -u 9901 --no-log-init -m -r -g terraform terraform

WORKDIR /root
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.io,direct
# the lausser fork contains a patch which copies a cloud-init's dhcp
# unicast ipv4 address to self.ssh_host
#RUN git clone https://github.com/lausser/terraform-provider-proxmox

RUN go get github.com/Telmate/proxmox-api-go && \
    go install github.com/Telmate/proxmox-api-go && \
    cp go/bin/proxmox-api-go /usr/local/bin

RUN go get github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox

# remove later, after the pull request has been accepted
#RUN cp terraform-provider-proxmox/proxmox/resource_vm_qemu.go ./go/pkg/mod/github.com/!telmate/terraform-provider-proxmox@*/proxmox/resource_vm_qemu.go
#RUN rm -rf terraform-provider-proxmox
RUN go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox && \
    cp go/bin/terraform-provider-proxmox /usr/local/bin

RUN go install github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provisioner-proxmox && \
    cp go/bin/terraform-provisioner-proxmox /usr/local/bin
RUN rm -rf go

USER terraform
WORKDIR /home/terraform
RUN  mkdir /home/terraform/.ssh && \
    chmod 700 /home/terraform/.ssh && \
    ssh-keygen -f /home/terraform/.ssh/id_rsa -N ""

RUN mkdir -p /home/terraform/.terraform.d/plugins/github.com/telmate/proxmox/1.0.0/linux_amd64 && \
    cp /usr/local/bin/terraform-provider-proxmox  /home/terraform/.terraform.d/plugins/github.com/telmate/proxmox/1.0.0/linux_amd64/ && \
    cp /usr/local/bin/terraform-provisioner-proxmox /home/terraform/.terraform.d/plugins/github.com/telmate/proxmox/1.0.0/linux_amd64/

USER root
COPY runtf.sh /home/terraform
COPY main.tf /home/terraform
COPY version.tf /home/terraform
RUN chown terraform:terraform /home/terraform/*
RUN chmod 755 /home/terraform/runtf.sh

USER terraform
RUN cp .ssh/id* .

ENTRYPOINT ["/home/terraform/runtf.sh"]
