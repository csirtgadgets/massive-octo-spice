SUBDIRS = libcif router smrt extern
EXTRA_DIST = sbin etc contrib config.layout .deps

BUILD=$(shell git describe --tags)
CIF_LAYOUT = @cif_layout_name@

all: default

default:

fixdeps:
	$(PERL) ./sbin/test-deps --verbose --install --prefix $(prefix)

testdeps:
	$(PERL) ./sbin/test-deps --verbose --prefix $(prefix)

test: extern-test libcif-test router-test smrt-test

extern-test:
	( cd extern && make test )

libcif-test:
	( cd libcif && make test )

router-test:
	( cd router && make test )

smrt-test:
	( cd smrt && make test )

install: files-install fixperms

files-install: libcif-install router-install smrt-install var-install etc-install extern-install

etc-install:
	[ -d $(CIF_PATH)/$(sysconfdir) ] || $(INSTALL) -m 0750 -d $(CIF_PATH)/$(sysconfdir)

var-install:
	[ -d $(CIF_PATH)/$(localstatedir) ] || $(INSTALL) -m 0750 -d $(CIF_PATH)/$(localstatedir)
	[ -d $(CIF_PATH)/$(localstatedir)/log ] || $(INSTALL) -m 0750 -d $(CIF_PATH)/$(localstatedir)/log

libcif-install:
	( cd libcif && make install )

router-install:
	( cd router && make install )

smrt-install:
	( cd smrt && make install )

extern-install:
	( cd extern && make install )

fixperms:
	chmod 0755 $(prefix)
	chown -R $(CIF_USER) $(prefix)
	chgrp -R $(CIF_GROUP) $(prefix)

clean:
	rm Makefile
	rm config.log
	rm config.status

realclean:
	clean
	rm Makefile.in
	rm configure
	rm aclocal.m4

reconf:
	autoreconf -vf
