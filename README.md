Getting Involved
===
[Project Page](http://csirtgadgets.org/cif/v2)  
[Mailing List](https://groups.google.com/forum/#!forum/ci-framework)  
[Contribute!](http://csirtgadgets.org/contribute)  

[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

From Distribution
===
* (unstable) [Debian](http://csirtgadgets.org/contribute)
* (unstable) [Ubuntu](http://csirtgadgets.org/contribute)
* (unstable) [CentOS](http://csirtgadgets.org/contribute)
* (unstable) [RHEL](http://csirtgadgets.org/contribute)
* (unstable) [FreeBSD](http://csirtgadgets.org/contribute)
* (unstable) [OSX](http://csirtgadgets.org/contribute)

From Source
===
Prerequisites
====
_([currently only debian/ubuntu supported this way](http://csirtgadgets.org/contribute))_
```
$ sudo bash ./prep/operatingsystem.sh
```

ElasticSearch
====
Make sure [Elastic Search](http://www.elasticsearch.org/overview/elasticsearch/) is [installed, configured and started](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/setup.html).

Installation
==
1. configure and install:

    ```
    $ ./configure --prefix=/opt/cif --localstatedir=/var --sysconfdir=/etc/cif
    $ make
    $ sudo make deps
    $ make test
    $ sudo make install
    $ make initdb
    ```
    notes:  
        * ``configure.ac`` defaults to ``/opt/cif`` even without ``--prefix``  
        * ``sudo make deps`` could take upwards of 30min or more on slower systems

1. configure your environment:

    ```
    $ echo "PATH=/opt/cif/bin:$PATH" >> ~/.profile
    $ source ~/.profile
    $ cif -h
    ```
1. start the router and smrt:

  ```
  $ sudo -u cif /opt/cif/bin/cif-router -D start
  $ sudo -u cif /opt/cif/bin/cif-smrt -D start
  ```

Notes
==
PerlBrew
====
Using the latest version of perl can drastically improve performance. This is not required, but recommended. Perlbrew will compile the latest version of perl on your system, the process takes anywhere from 15-45min depending on system resources. A simplified version of the PerlBrew instructions can be found [here](https://github.com/csirtgadgets/massive-octo-spice/wiki/PerlBrew). This should be done before running ./configure so autoconf picks up the correct perl path before building the modules.

COPYRIGHT AND LICENCE
==

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.
