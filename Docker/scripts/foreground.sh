#!/bin/bash
#
# https://github.com/jbfink/docker-wordpress/blob/master/scripts/foreground.sh
#
read pid cmd state ppid pgrp session tty_nr tpgid rest < /proc/self/stat
trap "kill -TERM -$pgrp; exit" EXIT TERM KILL SIGKILL SIGTERM SIGQUIT

source /etc/apache2/envvars
apache2 -D FOREGROUND
