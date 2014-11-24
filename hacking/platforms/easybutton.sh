#!/bin/bash

set -e

if [ `whoami` != 'root' ]; then
    echo "must be run as root"
    exit 1
fi

cd hacking/platforms

ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

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
        cd ubuntu
        bash ./ubuntu.sh;;

    "Debian" )
        echo 'Debian not yet supported...';;
        exit 1

    "Darwin" )
        echo 'Darwin not yet supported...' ;;
        exit 1

    "Redhat" )
        echo 'Redhat not yet supported...' ;;
        exit 1

    "CentOS" )
        echo 'CentOS not yet supported...' ;;
        exit 1

esac
