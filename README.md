Getting Involved
===
[Project Page](http://csirtgadgets.org/cif/v2)  
[Mailing List](https://groups.google.com/forum/#!forum/ci-framework)  
[Contribution Process](http://csirtgadgets.org/contribute)  
[Branching Model](http://nvie.com/posts/a-successful-git-branching-model/)

[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

Building and Installation
===
Operating System
====
Currently only debian is functional, others to follow.
1. setup the OS
```
$ sudo ./prep/operatingsystem.sh
```
PerlBrew
====
Using the latest version of perl can drastically improve performance. This is not required, but recommended. Perlbrew will compile the latest version of perl on your system, the process takes anywhere from 15-45min depending on system resources.
```
$ sudo ./prep/perlbrew.sh
$ echo "source ${PERLBREW_ROOT}/etc/bashrc" >> ${HOME}/.bash_profile
```

CIF
====
1. configure and install
```
$ ./configure
$ make testdeps
$ sudo make fixdeps
$ make && make test
$ sudo make install
$ sudo service elasticsearch start
$ make initdb
```
1. set the appropriate paths ($HOME/.profile)
```
if [ -d "/opt/cif/bin" ]; then
    PATH="/opt/cif/bin:$PATH"
fi
```
1. start the router
```
$ sudo service cif-router start
```

COPYRIGHT AND LICENCE
===

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.
