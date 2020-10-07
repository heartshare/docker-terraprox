#! /bin/sh
mkdir work
maintf=`find / -name main.tf 2>/dev/null | head -1`
cp -r `dirname $maintf`/* work
cd work
test -f id_rsa && chmod 600 id_rsa
terraform init
#terraform apply --auto-approve $*
terraform $* --auto-approve
