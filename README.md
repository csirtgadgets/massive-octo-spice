massive-octo-spice
==
[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice) [![Coverage Status](https://coveralls.io/repos/csirtgadgets/massive-octo-spice/badge.png?branch=master)](https://coveralls.io/r/csirtgadgets/massive-octo-spice?branch=master)

[Getting Involved](http://csirtgadgets.org/contribute)
[Repository](https://github.com/csirtgadgets/massive-octo-spice)

Building and Installation
===
Operating System
====
Currently only debian is supported, others to follow.
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
```
$ ./configure
$ make testdeps
$ sudo make fixdeps
$ make && make test
$ sudo make install
```

COPYRIGHT AND LICENCE
===

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.
