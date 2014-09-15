#!/bin/sh

set -e

if [ ! $VERSION ]; then
    VERSION=`git describe --tags`
fi

echo $VERSION | tr -d "\n"
