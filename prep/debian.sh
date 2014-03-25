#!/bin/bash

set -e

apt-get update
apt-get install -qq python-software-properties
echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
apt-get update
apt-get install -y build-essential git-core automake cpanminus rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart

# cif specific stuff
apt-get install -y libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl sqlite3 libxml2-dev libexpat-dev nginx

useradd cif
