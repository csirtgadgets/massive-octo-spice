#!/bin/sh

VERSION=`cat .version`

echo $VERSION | tr -d "\n"
