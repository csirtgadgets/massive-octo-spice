#!/bin/bash

##TODO -- build this as a package
## this is just a helper for now

set -e

MYUSER=cif
MYGROUP=cif

if [ `whoami` != 'root' ]; then
    echo 'this script must be run as root'
    exit 0
fi

cd hacking/platforms/ubuntu

apt-get update
apt-get install -qq python-software-properties
echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -

if [ -f /etc/apt/sources.list.d/elasticsearch.list ]; then
    echo "sources.list.d/elasticsearch.list already exists, skipping..."
else
    echo "deb http://packages.elasticsearch.org/elasticsearch/1.0/debian stable main" >> /etc/apt/sources.list.d/elasticsearch.list
fi

apt-get update
apt-get install -y curl cpanminus build-essential libmodule-build-perl libssl-dev elasticsearch apache2 libapache2-mod-perl2 curl mailutils build-essential git-core automake cpanminus rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9 libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl libxml2-dev libexpat-dev libgeoip-dev geoip-bin

cpanm Regexp::Common http://cpan.metacpan.org/authors/id/S/SH/SHERZODR/Config-Simple-4.59.tar.gz http://cpan.metacpan.org/authors/id/N/NL/NLNETLABS/Net-DNS-0.76_2.tar.gz Mouse

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools
service rng-tools restart

echo 'setting up bind...'

if [ -z `grep -l '8.8.8.8' /etc/bind/named.conf.options` ]; then
	echo 'overwriting bind config'
	cp /etc/bind/named.conf.options /etc/bind/named.conf.options.orig
	cp named.conf.options /etc/bind/named.conf.options
fi

if [ -z `grep -l 'spamhaus.org' /etc/bind/named.conf.local` ]; then
    cat ./named.conf.local >> /etc/bind/named.conf.local
fi

service bind9 restart

if [ -z `grep -l '127.0.0.1' /etc/resolvconf/resolv.conf.d/base` ]; then
    echo 'adding 127.0.0.1 as nameserver'
    echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/base
    echo "restarting network..."
    ifdown eth0 && sudo ifup eth0
fi

echo 'setting up apache'
cp cif.conf /etc/apache2/
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.orig
cp default-ssl /etc/apache2/sites-available/default-ssl.conf
a2dissite 000-default.conf
a2ensite default-ssl.conf
a2enmod ssl

service apache2 restart

if [ -z `getent passwd $MYUSER` ]; then
	echo "adding user: $MYUSER"
	useradd $MYUSER -m -s /bin/bash
	adduser www-data $MYUSER
fi

echo 'starting elastic search'
update-rc.d elasticsearch defaults 95 10
service elasticsearch start

cd ../../../