#!/bin/bash

export PERL5LIB=/opt/cif/lib/perl5

usage="$(basename "$0") [-h] [-p] -- program to get the version of CIF

where:
    -h  show this help text
    -p  print the version number with a new line (human readable)"


if [ $# -eq 0 ]; then
  perl -MCIF -e 'print CIF::VERSION'
  exit 0
else
  while getopts 'hp' option; do
    case "$option" in
      h) echo "$usage"
         exit 0
         ;;
      p) perl -MCIF -e 'print CIF::VERSION ."\n"'
         exit 0
         ;;
    esac
  done
  shift $((OPTIND - 1))
fi
