#!/bin/bash

set -e

PERL_VERSION=perl-5.18.2
PERLBREW_ROOT=/opt/perl5/perlbrew

cpanm -n -f -q App::perlbrew

PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew init

. ${PERLBREW_ROOT}/etc/bashrc
PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew install -v ${PERL_VERSION} -n -Dusethreads
PERLBREW_ROOT=${PERLBREW_ROOT} perlbrew install-cpanm
