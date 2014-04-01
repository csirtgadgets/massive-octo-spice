SUBDIRS = libcif router smrt extern schema
EXTRA_DIST = sbin contrib config.layout .deps contrib/client.conf

BUILD=$(shell git describe --tags)
CIF_LAYOUT = @cif_layout_name@

all: default

default:

fixdeps:
	$(PERL) ./sbin/test-deps --verbose --install

testdeps:
	$(PERL) ./sbin/test-deps --verbose

test: libcif-test router-test smrt-test

extern-test:
	( cd extern && make test )

libcif-test:
	( cd libcif && make test )

router-test:
	( cd router && make test )

smrt-test:
	cd smrt && make test

install: files-install fixperms

files-install: contrib-install libcif-install router-install smrt-install var-install etc-install extern-install

contrib-install:
	[ -d $(DESTDIR)$(CIF_PATH)/contrib ] || $(INSTALL) -m 0760 -d $(DESTDIR)$(CIF_PATH)/contrib
	-( cd contrib && find . -type d -print ) | while read dir ; do \
    	$(INSTALL) -m 0750 -d "$(DESTDIR)$(CIF_PATH)/contrib/$$dir" ; \
    done
	-( cd contrib && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
    	$(INSTALL) -m 0660 "contrib/$$file" "$(DESTDIR)$(CIF_PATH)/contrib/$$file" ; \
    done
	
etc-install:
	[ -d $(DESTDIR)$(CIF_PATH)/$(sysconfdir) ] || $(INSTALL) -m 0750 -d $(DESTDIR)$(CIF_PATH)/$(sysconfdir)

var-install:
	[ -d $(DESTDIR)$(CIF_PATH)/$(localstatedir) ] || $(INSTALL) -m 0750 -d $(DESTDIR)$(CIF_PATH)/$(localstatedir)
	[ -d $(DESTDIR)$(CIF_PATH)/$(localstatedir)/log ] || $(INSTALL) -m 0750 -d $(DESTDIR)$(CIF_PATH)/$(localstatedir)/log

libcif-install:
	( cd libcif && make install )

router-install:
	( cd router && make install )

smrt-install:
	( cd smrt && make install )

extern-install:
	( cd extern && make install )

initdb:
	( cd schema && make initdb )

removedb:
	( cd schema && make removedb )

reloaddb: removedb initdb

fixperms:
	chmod 0755 $(DESTDIR)$(prefix)
	chown -R $(CIF_USER) $(DESTDIR)$(prefix)
	chgrp -R $(CIF_GROUP) $(DESTDIR)$(prefix)

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

dist-hook:
	rm -rf $(distdir)/puppet
	rm -rf $(distdir)/provision
	rm -rf $(distdir)/build
