#!/bin/bash

set -e

DEPS=`cat .deps`
cpanm -n -f -q ${DEPS}
