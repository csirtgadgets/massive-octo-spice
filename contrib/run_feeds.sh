#!/bin/bash

CONFIDENCE="65"
BIN="perl -I/vagrant/p5-cif-sdk/lib /vagrant/p5-cif-sdk/bin/cif-feed -d"

set -e

$BIN --otype ipv4 --confidence $CONFIDENCE --tags scanner
#$BIN --otype ipv4,fqdn,url --confidence $CONFIDENCE --tags botnet
#$BIN --otype ipv4,fqdn,url --confidence $CONFIDENCE --tags malware
#$BIN --otype ipv4,fqdn,url --confidence $CONFIDENCE --tags phishing
#$BIN --otype ipv4,fqdn,url --confidence $CONFIDENCE --tags suspicious
