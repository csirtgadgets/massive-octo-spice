#!/bin/bash

set -e

ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    VER=$(cat /etc/debian_version)
    sh /vagrant/provision/ubuntu.sh
elif [ -f /etc/redhat-release ]; then
    # TODO add code for Red Hat and CentOS here
    ...
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

if [ $OS == 'Darwin' ]; then
    echo 'Darwin not currently supported...'
    exit
fi

sh /vagrant/provision/perlbrew.sh
sh /vagrant/provision/cpanm.sh
