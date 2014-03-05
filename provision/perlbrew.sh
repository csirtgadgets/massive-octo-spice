#!/bin/bash

set -e

FLAG=/tmp/.provisioned_perlbrew

if [ -e $FLAG ]; then
    echo 'already provisioned perlbrew...'
    exit
fi

mkdir /opt/perl5
export PERLBREW_ROOT=/opt/perl5
perlbrew init
source ${PERLBREW_ROOT}/etc/bashrc
echo "export PERLBREW_ROOT=/opt/perl5" >> /home/vagrant/.profile
echo "source ${PERLBREW_ROOT}/etc/bashrc" >> /home/vagrant/.profile
exec /bin/bash
perlbrew install -v perl-5.18.2 -n --switch -Dusethreads
perlbrew install-cpanm
chown vagrant:vagrant /home/vagrant/.perlbrew -R

touch $FLAG
