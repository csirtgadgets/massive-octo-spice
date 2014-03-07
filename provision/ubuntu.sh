#!/bin/bash

set -e

FLAG=/tmp/.provisioned_ubuntu

if [ -e $FLAG ]; then
    echo 'already provisioned...'
    exit
fi

# zmq keys
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 136221EE520DDFAF0A905689B9316A7BC7917B12
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
echo "deb http://ppa.launchpad.net/chris-lea/zeromq/ubuntu precise main" >> /etc/apt/sources.list
echo "deb-src http://ppa.launchpad.net/chris-lea/zeromq/ubuntu precise main" >> /etc/apt/sources.list
echo "deb http://packages.elasticsearch.org/elasticsearch/1.0/debian stable main" >> /etc/apt/sources.list
# echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"

# system stuff
aptitude hold grub-common grub-pc
apt-get update
apt-get install -y build-essential git-core automake cpanminus rng-tools perlbrew openjdk-7-jre-headless elasticsearch libtool pkg-config
apt-get install vim htop -y
echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart
echo "alias aptitude='aptitude -F \"%p %V %v %d\"'" >> /home/vagrant/.profile

apt-get install -y libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl sqlite3 libxml2-dev libexpat-dev

useradd cif

touch $FLAG
