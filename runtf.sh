#! /bin/sh
maintf=`find / -name main.tf 2>/dev/null | head -1`
cd `dirname $maintf`
terraform init
terraform apply --auto-approve $*
