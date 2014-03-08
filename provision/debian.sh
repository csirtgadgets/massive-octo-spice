#!/bin/bash

set -e

FLAG=/tmp/.provisioned_ubuntu

if [ -e $FLAG ]; then
    echo 'already provisioned...'
    exit
fi

apt-get update
apt-get install -qq python-software-properties
echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
apt-get update
apt-get install -y build-essential git-core automake cpanminus rng-tools openjdk-7-jre-headless libtool pkg-config vim htop

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart
echo "alias aptitude='aptitude -F \"%p %V %v %d\"'" >> /home/vagrant/.profile

# cif specific stuff
apt-get install -y libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl sqlite3 libxml2-dev libexpat-dev

useradd cif

touch $FLAG
