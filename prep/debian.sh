#!/bin/bash

set -e

apt-get update
apt-get install -qq python-software-properties
echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

if [ -f /etc/apt/sources.list.d/elasticsearch ]; then
    echo "sources.list.d/elasticsearch already exists, skipping..."
else
    echo "deb http://packages.elasticsearch.org/elasticsearch/1.0/debian stable main" >> /etc/apt/sources.list.d/elasticsearch
fi

apt-get update
apt-get install -y curl mailutils build-essential git-core automake cpanminus rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9 libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl libxml2-dev libexpat-dev nginx

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart

useradd cif
adduser www-data cif

if [ `grep -l '127.0.0.1' /etc/resolvconf/resolv.conf.d/base` ]; then
    echo 'nameserver already set to localhost, skipping...'
else
    echo 'adding 127.0.0.1 as nameserver'
    echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/base
    echo "restarting network..."
    ifdown eth0 && sudo ifup eth0
fi

update-rc.d elasticsearch defaults 95 10
service elasticsearch start
