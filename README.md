Getting Involved
===
[Project Page](http://csirtgadgets.org/cif/v2)  
[Mailing List](https://groups.google.com/forum/#!forum/ci-framework)  
[Contribute!](http://csirtgadgets.org/contribute)  

[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

Notes
====
* this can be an EC2-like instance, but be ware of the network activity coming from the box, it could be flagged as malicious, check with your provider's policies
* with post processing, these boxes make a lot of threaded DNS resoultion requests, make sure you understand your operating environment and work with your network team to address high volume dns queries

Platform Requirements
===
Small Instance
====
* an x86-64bit platform (vm or bare-metal)
* at-least 8GB ram
* at-least 8 cores
* at-least 100GB of free (after OS install) disk space

Large Instance
====
* an x86-64bit platform (bare-metal)
* at-least 32GB ram
* at-least 32 cores
* at-least 500GB of free (after OS install) disk space
* RAID + LVM knowledge

From Distribution
===
* (unstable) [Debian](http://csirtgadgets.org/contribute)
* (unstable) [Ubuntu](https://launchpad.net/~cif)
* (unstable) [CentOS](http://csirtgadgets.org/contribute)
* (unstable) [RHEL](http://csirtgadgets.org/contribute)
* (unstable) [FreeBSD](http://csirtgadgets.org/contribute)
* (unstable) [OSX](http://csirtgadgets.org/contribute)

From Source
===
Operating System
====
_([currently only debian/ubuntu](http://csirtgadgets.org/contribute))_
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
    $ sudo make fix-perms
    $ make es-init
    ```
    notes:  
        * ``configure.ac`` defaults to ``/opt/cif`` even without ``--prefix``  
        * ``sudo make deps`` could take upwards of 30min or more on slower systems  
        * to skip cpanm dep testing [faster, not recommended]: ``sudo make deps NOTESTS=-n``  
        * ``make es-init`` should respond back with ``{"acknowledged":true}`` upon success  
        * ``sudo fix-perms`` will default to the ``--with-user`` and ``--with-group`` and only affects ``${sysconfdir}/etc``

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
