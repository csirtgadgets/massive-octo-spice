#!/bin/bash

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
apt-get install -qq software-properties-common python-software-properties

if [ ! -f /etc/apt/sources.list.d/chris-lea-zeromq-trusty.list ]; then
    echo 'adding updated zmq repo....'
    echo "yes" | sudo add-apt-repository "ppa:chris-lea/zeromq"
    echo "yes" | sudo add-apt-repository "ppa:maxmind/ppa"
    wget -O - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
fi

if [ -f /etc/apt/sources.list.d/elasticsearch.list ]; then
    echo "sources.list.d/elasticsearch.list already exists, skipping..."
else
    echo "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main" >> /etc/apt/sources.list.d/elasticsearch.list
fi

debconf-set-selections <<< "postfix postfix/mailname string localhost"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get update
apt-get install -y monit geoipupdate curl build-essential libmodule-build-perl libssl-dev elasticsearch apache2 libapache2-mod-perl2 curl mailutils build-essential git-core automake rng-tools openjdk-7-jre-headless libtool pkg-config vim htop bind9 libzmq3-dev libffi6 libmoose-perl libmouse-perl libanyevent-perl liblwp-protocol-https-perl libxml2-dev libexpat1-dev libgeoip-dev geoip-bin python-dev starman ntp

#if [ ! -d /usr/share/elasticsearch/plugins/marvel ]; then
#    echo 'installing marvel for elasticsearch...'
#    /usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/latest
#fi

echo 'installing cpanm...'
curl -L https://cpanmin.us | sudo perl - App::cpanminus
alias cpanm='cpanm --wget --mirror https://cpan.metacpan.org'

cpanm Regexp::Common
cpanm Moo@1.007000
cpanm Mouse@2.4.1
cpanm ZMQ::FFI@0.17
cpanm --force --notest https://github.com/csirtgadgets/ZMQx-Class/archive/master.tar.gz
cpanm Log::Log4perl@1.44
cpanm Test::Exception@0.32
cpanm MaxMind::DB::Reader@0.050005
cpanm GeoIP2@0.040005
cpanm Hijk@0.19
cpanm https://github.com/csirtgadgets/p5-cif-sdk/archive/master.tar.gz
cpanm https://github.com/kraih/mojo/archive/v5.82.tar.gz
cpanm Search::Elasticsearch@1.19

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

echo 'restarting bind...'
service bind9 restart

if [ -z `grep -l '^prepend domain-name-servers 127.0.0.1;' /etc/dhcp/dhclient.conf` ]; then
    cp dhclient.conf /etc/dhcp/
fi

if [ -z `grep -l '127.0.0.1' /etc/resolvconf/resolv.conf.d/base` ]; then
    echo 'adding 127.0.0.1 as nameserver'
    echo "nameserver 127.0.0.1" >> /etc/resolvconf/resolv.conf.d/base
    echo "restarting network..."
    ifdown eth0 && sudo ifup eth0
fi

echo 'setting up apache'
if [ ! -f /etc/apache2/cif.conf ]; then
    /bin/cp cif.conf /etc/apache2/
fi

if [ $VER == "12.04" ]; then
    cp /etc/apache2/sites-available/default-ssl /etc/apache2/sites-available/default-ssl.orig
    cp default-ssl /etc/apache2/sites-available
    a2dissite default
    a2ensite default-ssl
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf.d/security
    sed -i 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf.d/security
    sed -i 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf.d/security
elif [ $VER == "14.04" ]; then
    cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.orig
    cp default-ssl /etc/apache2/sites-available/default-ssl.conf
    a2dissite 000-default.conf
    a2ensite default-ssl.conf
    sed -i 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
    sed -i 's/^ServerSignature On/#ServerSignature On/' /etc/apache2/conf-enabled/security.conf
    sed -i 's/^#ServerSignature Off/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf

    if [ ! -f /etc/apache2/conf-available/servername.conf ]; then
        echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf
        a2enconf servername
    fi
fi

a2enmod ssl proxy proxy_http

if [ -z `getent passwd $MYUSER` ]; then
    echo "adding user: $MYUSER"
    useradd $MYUSER -m -s /bin/bash
    adduser www-data $MYUSER
fi

echo 'starting elastic search'
update-rc.d elasticsearch defaults 95 10
service elasticsearch restart

set +e
echo 'removing old elastic search templates'
curl -XDELETE http://localhost:9200/_template/template_cif_observables > /dev/null 2>&1
curl -XDELETE http://localhost:9200/_template/template_cif_tokens > /dev/null 2>&1
set -e

cd ../../../

./configure --enable-geoip --sysconfdir=/etc/cif --localstatedir=/var --prefix=/opt/cif
make && make deps NOTESTS=-n
make test
make install
make fixperms
make elasticsearch

if [ ! -f /etc/default/cif ]; then
	echo 'setting /etc/default/cif'
	cp ./hacking/packaging/ubuntu/default/cif /etc/default/cif
fi

if [ ! -f /home/cif/.profile ]; then
    touch /home/cif/.profile
    chown $MYUSER:$MYGROUP /home/cif/.profile
fi

mkdir -p /var/smrt/cache
chown -R $MYUSER:$MYGROUP /var/smrt

if [ -z `grep -l '/opt/cif/bin' /home/cif/.profile` ]; then
    MYPROFILE=/home/$MYUSER/.profile
    echo "" >> $MYPROFILE
    echo "# automatically generated by CIF installation" >> $MYPROFILE
    echo 'PATH=/opt/cif/bin:$PATH' >> $MYPROFILE
fi

if [ ! -f /etc/cif/cif-smrt.yml ]; then
    echo 'setting up /etc/cif/cif-smrt.yml config...'
    /opt/cif/bin/cif-tokens --username cif-smrt --new --write --generate-config-remote http://localhost:5000 --generate-config-path /etc/cif/cif-smrt.yml
    chown cif:cif /etc/cif/cif-smrt.yml
    chmod 660 /etc/cif/cif-smrt.yml
fi

if [ ! -f /etc/cif/cif-worker.yml ]; then
    echo 'setting up /etc/cif/cif-worker.yml config...'
    /opt/cif/bin/cif-tokens --username cif-worker --new --read --write --generate-config-remote tcp://localhost:4961 --generate-config-path /etc/cif/cif-worker.yml
    chown cif:cif /etc/cif/cif-worker.yml
    chmod 660 /etc/cif/cif-worker.yml
fi

if [ ! -f ~/.cif.yml ]; then
    echo 'setting up ~/.cif.yml config for user: root@localhost...'
    /opt/cif/bin/cif-tokens --username root@localhost --new --read --write --generate-config-remote https://localhost --generate-config-path ~/.cif.yml
    chmod 660 ~/.cif.yml
fi

echo "setting up log rotation"
cp ./hacking/platforms/ubuntu/cif.logrotated /etc/logrotate.d/cif

echo 'setting default cif-starman.conf'
cp ./hacking/platforms/ubuntu/cif-starman.conf /etc/cif/

if [ -f /etc/init.d/cif-router ]; then
	update-rc.d -f cif-router remove 95 10
	update-rc.d -f cif-smrt remove 95 10
	update-rc.d -f cif-worker remove 95 10
	update-rc.d -f cif-starman remove 95 10
else
	echo 'copying init.d scripts...'
	/bin/cp ./hacking/packaging/ubuntu/init.d/cif-smrt /etc/init.d/
	/bin/cp ./hacking/packaging/ubuntu/init.d/cif-router /etc/init.d/
	/bin/cp ./hacking/packaging/ubuntu/init.d/cif-starman /etc/init.d/
	/bin/cp ./hacking/packaging/ubuntu/init.d/cif-worker /etc/init.d/
	/bin/cp ./hacking/packaging/ubuntu/init.d/cif-services /etc/init.d/
fi

update-rc.d cif-services defaults 99 01

echo 'staring cif-services...'
sudo service cif-services start

echo 'restarting apache...'
service apache2 restart

echo 'setting up geoipupdate...'
cp ./hacking/platforms/ubuntu/GeoIP.conf /etc/
cp ./hacking/platforms/ubuntu/geoipupdate.cron /etc/cron.monthly/geoipupdate.sh
chmod 755 /etc/cron.monthly/geoipupdate.sh

# work-around for cif-router mem leak
# https://github.com/csirtgadgets/massive-octo-spice/issues/155
# it's crappy, but its a work-around atm, perl just doesn't like to give up memory
cp ./hacking/platforms/ubuntu/cif-router.cron /etc/cron.weekly/cif-router
chmod 755 /etc/cron.weekly/cif-router

cp ./hacking/platforms/ubuntu/cif-worker.cron /etc/cron.weekly/cif-worker
chmod 755 /etc/cron.weekly/cif-worker

echo 'setting up monit...'
cp ./hacking/platforms/ubuntu/cif.monit /etc/monit/conf.d/cif
cp ./hacking/platforms/ubuntu/elasticsearch.monit /etc/monit/conf.d/elasticsearch
echo 'restarting monit...'
service monit restart
