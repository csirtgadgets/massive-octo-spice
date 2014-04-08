SUBDIRS = schema build
EXTRA_DIST = libcif smrt router sbin contrib .deps

BUILD=$(shell git describe --tags)
PERLOPTS=DESTDIR=$(DESTDIR) INSTALL_BASE=$(CIF_PATH) INSTALLPRIVLIB=${siteperldir}

all: default

default: libcif smrt router
test: libcif-test smrt-test router-test

# http://stackoverflow.com/questions/3931741/why-does-make-think-the-target-is-up-to-date
.PHONY: libcif smrt router

libcif:
	( cd libcif && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

libcif-testdeps:
	( cd libcif && make testdeps )

libcif-fixdeps:
	( cd libcif && make fixdeps )
 
libcif-test:
	( cd libcif && CRITIC=$(PERL_CRITIC) make test )

libcif-install:
	( cd libcif && make install )

smrt:
	( cd smrt && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

smrt-testdeps:
	( cd smrt && make testdeps )

smrt-test:
	(cd smrt && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

smrt-install:
	( cd smrt && make install )

smrt-install-rules:
	[ -d $(DESTDIR)$(sysconfdir)/rules ] || $(INSTALL) -m 0750 -d $(DESTDIR)$(sysconfdir)/rules
	-( cd smrt/rules && find . -type d -print ) | while read dir ; do \
		$(INSTALL) -m 0750 -d "$(DESTDIR)$(sysconfdir)/rules/$$dir" ; \
	done
	-( cd smrt/rules && find . -type f -print ) | while read file ; do \
		$(INSTALL) -m 0660 "smrt/rules/$$file" "$(DESTDIR)$(sysconfdir)/rules/$$file" ; \
    done

router:
	( cd router && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

router-testdeps:
	( cd router && make testdeps )

router-fixdeps:
	( cd router && make fixdeps )

router-test:
	( cd router && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

router-install:
	( cd router && make install)

fixdeps: libcif-fixdeps
	cat .deps | while read mydep ; do \
        @CPANM@ $$mydep ; \
    done

testdeps: libcif-testdeps
	$(PERL) ./sbin/test-deps --verbose

install-debian: install
	( cd build && make install-debian )

install: libcif-install router-install smrt-install

initdb:
	( cd schema && make initdb )

dropdb:
	( cd schema && make dropdb )

reloaddb: dropdb initdb

clean:
	find . -name 'MANIFEST' -delete
	find . -name 'MANIFEST.bak' -delete
	( cd libcif && $(PERL) Makefile.PL && make realclean )
	( cd smrt && $(PERL) Makefile.PL && make realclean )
	( cd router && $(PERL) Makefile.PL && make realclean )

reconf:
	autoreconf -vf

dist-hook:
	rm -rf $(distdir)/puppet
	rm -rf $(distdir)/prep
	rm -rf $(distdir)/libcif/blib
	rm -rf $(distdir)/smrt/blib
	rm -rf $(distdir)/router/blib
	find $(distdir)/smrt/testdata -name '*.log' -delete
	find $(distdir) -name 'Makefile' -delete
	find $(distdir) -name 'pm_to_blib' -delete
	find $(distdir) -name 'CIF-.tar.gz' -delete
	find $(distdir) -name '*.old' -delete
	find $(distdir) -name '*.bak' -delete
	find $(distdir) -name '.DS_Store' -delete
