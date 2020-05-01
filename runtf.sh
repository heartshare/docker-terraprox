#! /bin/sh
maintf=`find / -name main.tf 2>/dev/null | head -1`
mkdir work
cp -r `dirname $maintf`/* work
cd work
terraform init
#terraform apply --auto-approve $*
terraform $* --auto-approve
