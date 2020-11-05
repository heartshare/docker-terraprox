FROM hashicorp/terraform

RUN apk add --no-cache make musl-dev go rsync shadow python3
RUN apk add --no-cache bash python3-dev
RUN apk add --no-cache patch
RUN apk add --no-cache ansible
RUN apk add --no-cache sshpass
RUN apk add --no-cache util-linux
RUN apk add --no-cache curl
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

RUN go get  github.com/Telmate/terraform-provider-proxmox/cmd/terraform-provider-proxmox@0ee80674d823445f83db81af5d37523448d417df
# PR #230 introduces a bug (repl. return nil with ...VmRead)

RUN cp go/bin/terraform-provider-proxmox /usr/local/bin
RUN rm -rf go

USER terraform
WORKDIR /home/terraform
RUN  mkdir /home/terraform/.ssh && \
    chmod 700 /home/terraform/.ssh && \
    ssh-keygen -f /home/terraform/.ssh/id_rsa -N ""

RUN mkdir -p ./usr/share/terraform/plugins/terraform.local/local/proxmox/1.0.0/linux_amd64 && \
    cp /usr/local/bin/terraform-provider-proxmox ./usr/share/terraform/plugins/terraform.local/local/proxmox/1.0.0/linux_amd64/
# no provisioner needed for cloud-init

USER root
COPY entrypoint.sh /home/terraform
COPY main.tf /home/terraform
COPY version.tf /home/terraform
COPY variables.tf /home/terraform
COPY .terraformrc /home/terraform
RUN chown terraform:terraform /home/terraform/*
RUN chmod 755 /home/terraform/entrypoint.sh

USER terraform
RUN cp .ssh/id* .

ENTRYPOINT ["/home/terraform/entrypoint.sh"]
