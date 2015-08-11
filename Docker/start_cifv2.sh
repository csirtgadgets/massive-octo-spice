#!/bin/sh
#
# Aaron Eppert (aeppert@gamil.com)
#
# Wrapper script for starting the cifv2 Docker image 
#
VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 "cifv2_forward_5000,tcp,,5000,,5000"
VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 "cifv2_forward_443,tcp,,8443,,443"
VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 "cifv2_forward_9200,tcp,,9200,,9200"

docker run -d -p 443:8443 -p 5000:5000 -p 9200:9200 aeppert/cifv2

VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 delete "cifv2_forward_5000"
VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 delete "cifv2_forward_443"
VBoxManage controlvm "aeppert_default_1439320375987_38334" natpf1 delete "cifv2_forward_9200"
