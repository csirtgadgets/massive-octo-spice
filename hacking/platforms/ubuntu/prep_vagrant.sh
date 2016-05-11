#!/bin/bash

##
## HOWTO
##
## https://scotch.io/tutorials/how-to-create-a-vagrant-base-box-from-an-existing-one
## This can prob be the base script, called by ubuntu.sh..

set -e
shopt -s expand_aliases

. /etc/lsb-release

MYUSER=cif
MYGROUP=cif
VER=$DISTRIB_RELEASE

if [ `whoami` != 'root' ]; then
    echo 'this script must be run as root'
    exit 0
fi

apt-get update
apt-get install -qq python-software-properties

if [ ! -f /etc/apt/sources.list.d/chris-lea-zeromq-trusty.list ]; then
    echo 'adding updated zmq repo....'
    echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
    echo "yes" | sudo add-apt-repository "ppa:maxmind/ppa"
    wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
fi

if [ -f /etc/apt/sources.list.d/elasticsearch.list ]; then
    echo "sources.list.d/elasticsearch.list already exists, skipping..."
else
    echo "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main" >> /etc/apt/sources.list.d/elasticsearch.list
fi

debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get update
apt-get install -y monit geoipupdate curl build-essential libmodule-build-perl libssl-dev elasticsearch apache2 libapache2-mod-perl2 curl mailutils build-essential git-core automake rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9 libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl libxml2-dev libexpat1-dev libgeoip-dev geoip-bin python-dev starman

echo 'installing cpanm...'
curl -L https://cpanmin.us | sudo perl - App::cpanminus

alias cpanm='cpanm --wget --mirror https://cpan.metacpan.org'
cpanm Regexp::Common
cpanm Moo@1.007000
cpanm Test::Simple@1.001014
cpanm Mouse@2.4.1
cpanm ZMQ::FFI@0.17
cpanm ZMQx::Class --force
cpanm Log::Log4perl@1.44
cpanm Test::Exception@0.32
cpanm MaxMind::DB::Reader@0.050005
cpanm GeoIP2@0.040005
cpanm https://github.com/csirtgadgets/p5-cif-sdk/archive/master.tar.gz
cpanm https://github.com/kraih/mojo/archive/v5.82.tar.gz

cpanm --installdeps ./src
