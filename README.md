Getting Involved
==
[Project Page](http://csirtgadgets.org/cif/v2)  
[Mailing List](https://groups.google.com/forum/#!forum/ci-framework)  
[Contribute!](http://csirtgadgets.org/contribute)  

[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

Setup
==
From Distribution
===
* Debian
* Ubuntu
* CentOS
* RHEL
* FreeBSD
* OSX

From Source
===
Operating System
====
Setup the OS and it's deps

```
$ sudo ./prep/operatingsystem.sh
```
PerlBrew
====
Using the latest version of perl can drastically improve performance. This is not required, but recommended. Perlbrew will compile the latest version of perl on your system, the process takes anywhere from 15-45min depending on system resources. A simplified version of the PerlBrew instructions can be found [here](https://github.com/csirtgadgets/massive-octo-spice/wiki/PerlBrew).

ElasticSearch
====
Make sure [Elastic Search](http://www.elasticsearch.org/overview/elasticsearch/) is [installed, configured and started](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/setup.html).

Installation
==
1. configure and install

    ```
    $ ./configure --prefix=/opt/cif --localstatedir=/var --sysconfdir=/etc/cif
    $ make && sudo make deps
    $ make test
    $ sudo make install
    $ make initdb
    ```
    note: ``configure.ac will pick /opt/cif by default``
1. configure your environment

    ```
    $ echo "PATH=/opt/cif/bin:$PATH" >> ~/.profile
    $ source ~/.profile
    $ cif -h
    ```
1. start the router  

  ```
  $ sudo -u cif /opt/cif/bin/cif-router -D start
  $ sudo -u cif /opt/cif/bin/cif-smrt -D start
  ```

COPYRIGHT AND LICENCE
===

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.
