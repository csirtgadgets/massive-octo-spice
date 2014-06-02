#!/bin/bash

PERL_VERSION=perl-5.18.2
PERLBREW_ROOT=/home/vagrant/perl5/perlbrew
FLAG=/tmp/.provisioned_perlbrew

if [ -e $FLAG ]; then
    echo 'already provisioned perlbrew...'
    exit
fi

cpanm -n -f -q App::perlbrew

PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew init
echo "source ${PERLBREW_ROOT}/etc/bashrc" >> /home/vagrant/.bash_profile

. ${PERLBREW_ROOT}/etc/bashrc
PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew install -v ${PERL_VERSION} -n -Dusethreads
chown -R vagrant:vagrant ${PERLBREW_ROOT}

PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew install-cpanm
touch $FLAG
