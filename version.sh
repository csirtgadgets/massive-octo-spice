#!/bin/sh

set -e

VERSION=`git describe --tags`

echo $VERSION | tr -d "\n"
