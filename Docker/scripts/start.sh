#!/bin/sh
#
service bind9 start
service elasticsearch start
service cif-services start
service monit start

/etc/apache2/foreground.sh
