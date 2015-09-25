#!/bin/bash

set -e

if [ `whoami` != 'root' ]; then
    echo "ERROR: must be run as root"
    exit 0
fi

if [ $ARCH != 'x86_64' ]; then
    echo "ERROR: must install on a 64-bit OS"
    exit 0
fi

if [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    OS=Debian  # XXX or Ubuntu??
    VER=$(cat /etc/debian_version)
elif [ -f /etc/redhat-release ]; then
    # TODO add code for Red Hat and CentOS here
    ...
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

case $OS in
    "Ubuntu" )
        sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y python-pip python-crypto python-httplib2 python-jinja2 python-netaddr python-paramiko python-pkg-resources python-yaml git
        sudo pip install ansible
        if [ -d massive-octo-spice ]; then
            (cd massive-octo-spice && git checkout $BRANCH && git pull)
        else
            git clone https://github.com/csirtgadgets/massive-octo-spice.git -b $BRANCH
        fi
        cd massive-octo-spice/ansible
        ansible-playbook localhost.yml                

    "Debian" )
        echo 'Debian not yet supported...';;

    "Darwin" )
        echo 'Darwin not yet supported...' ;;

    "Redhat" )
        echo 'Redhat not yet supported...' ;;

    "CentOS" )
        echo 'CentOS not yet supported...' ;;

esac
