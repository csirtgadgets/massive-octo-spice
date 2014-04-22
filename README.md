Getting Involved
===
There are many ways to get involved with the project. If you have a new and exciting feature, or even a simple bugfix, simply [fork the repo](https://help.github.com/articles/fork-a-repo), create some simple test cases, [generate a pull-request](https://help.github.com/articles/using-pull-requests) and give yourself credit!
* [How To Contribute](contributing.md)  
* [Mailing List](https://groups.google.com/forum/#!forum/ci-framework)
* [Project Page](http://csirtgadgets.org/cif/v2)
* Master Build Status: [![Build Status](https://travis-ci.org/csirtgadgets/massive-octo-spice.png?branch=master)](https://travis-ci.org/csirtgadgets/massive-octo-spice)

Installation
==
See the [wiki](https://github.com/csirtgadgets/massive-octo-spice/wiki/Install).

TODO's
===
In order to get "the scaffolding" out, certain feature-sets are still [in the queue](https://github.com/csirtgadgets/massive-octo-spice).

* by default there is currently no HTTP/JSON interface, libcif communicates to cif-router via [ZeroMQ](http://zeromq.org). these additional interfaces (SDK's) will be made available in upcoming releases (perl/python/ruby).
* tokens (apikeys) support is not yet built in
* feed generation support is not yet built in
* "smrt analytics" (eg: FQDN resolution, etc) is not yet built in, and will likely move from cif-smrt to a publishing pipeline hanging off cif-router.
* currently, only some of the simplier feeds have been converted (mostly simple text parsing stuff), xml, json and other complex feeds have yet to be integrated.

COPYRIGHT AND LICENCE
==

Free use of this software is granted under the terms of the GNU Lesser General
Public License (LGPLv3). For details see the files `COPYING` included with the
distribution.

This product includes GeoLite2 data created by MaxMind, available from <a href="http://www.maxmind.com">http://www.maxmind.com</a>.
