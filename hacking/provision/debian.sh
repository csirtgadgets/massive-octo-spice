#!/bin/bash

set -e

FLAG=/tmp/.provisioned_ubuntu

if [ -e $FLAG ]; then
    echo 'already provisioned...'
    exit
fi

aptitude hold grub-common grub-pc
apt-get update
apt-get install -y build-essential git-core automake cpanminus rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9 curl

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart
echo "alias aptitude='aptitude -F \"%p %V %v %d\"'" >> /home/vagrant/.profile

touch $FLAG
