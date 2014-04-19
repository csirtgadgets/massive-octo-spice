#!/bin/bash

set -e

ME=`whoami`
if [ $ME != 'root' ]; then
    echo "debian_kibana.sh must be run as root"
    exit 0
fi

VERSION=3.0.1
FILE=kibana-$VERSION.tar.gz
URL=https://download.elasticsearch.org/kibana/kibana/$FILE
DASH=https://raw.githubusercontent.com/csirtgadgets/massive-octo-spice/develop/contrib/router/kibana-dashboard.json
DIR_WWW=/var/www
USER=www-data
GROUP=www-data
TMP=/tmp
NGINX=https://raw.githubusercontent.com/csirtgadgets/massive-octo-spice/develop/contrib/router/kibana-nginx.conf

if [ -d $DIR_WWW/kibana ]; then
    echo 'kibana already installed, remove first then try again'
    exit 0
fi

if [ ! -f /etc/nginx/sites-available/kibana.conf ]; then
    wget $NGINX -O /etc/nginx/sites-available/kibana.conf
    ln -sf /etc/nginx/sites-available/kibana.conf /etc/nginx/sites-enabled/kibana
fi

if [ ! -d $DIR_WWW ]; then
    mkdir $DIR_WWW
    chown -R $USER:$GROUP $DIR_WWW
    chmod 770 -R $DIR_WWW
fi

wget $URL -O $TMP/$FILE
tar -zxvf $TMP/$FILE -C /tmp
mv $TMP/kibana-$VERSION $DIR_WWW/kibana
mv $DIR_WWW/kibana/app/dashboards/default.json $DIR_WWW/kibana/app/dashboards/default.json.orig
wget $DASH -O $DIR_WWW/kibana/app/dashboards/default.json
chown -R $USER:$GROUP $DIR_WWW/kibana

service nginx restart
