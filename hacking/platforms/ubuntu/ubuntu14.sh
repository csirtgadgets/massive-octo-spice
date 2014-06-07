#!/bin/bash

set -e

if [ `whoami` != 'root' ]; then
    echo 'this script must be run as root'
    exit 0
fi

cd ../../../

apt-get install -y curl cpanminus build-essential
cpanm Regexp::Common http://search.cpan.org/CPAN/authors/id/S/SH/SHERZODR/Config-Simple-4.59.tar.gz
./configure --enable-geoip --sysconfdir=/etc/cif --localstatedir=/var --prefix=/opt/cif
bash ./hacking/platforms/ubuntu14_os.sh
make && make deps
make test
make install
make fixperms
make elasticsearch
