Getting Involved
===
[Project Page](http://csirtgadgets.org/cif/v2)  
[Mailing List](https://groups.google.com/forum/#!forum/ci-framework)  
[Contribute!](http://csirtgadgets.org/contribute)  

[![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

Installation
===
Operating System
====
Currently only debian is functional, others to follow.
```
$ sudo ./prep/operatingsystem.sh
```
PerlBrew
====
Using the latest version of perl can drastically improve performance. This is not required, but recommended. Perlbrew will compile the latest version of perl on your system, the process takes anywhere from 15-45min depending on system resources. A simplified version of the PerlBrew instructions can be found [here](https://github.com/csirtgadgets/massive-octo-spice/wiki/PerlBrew).

ElasticSearch
===
Make sure [Elastic Search](http://www.elasticsearch.org/overview/elasticsearch/) is [installed, configured and started](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/setup.html). If you're running Ubuntu, this is likely taken care of with: ``$ sudo ./prep/operatingsyste.sh``.

CIF
====
1. configure and install

    ```
    $ ./configure
    $ make && make test
    $ sudo make install
    $ make initdb
    ```
1. start the router  

  ```
  $ sudo service cif-router start
  $ sudo service cif-smrt start
  ```

COPYRIGHT AND LICENCE
===

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.
