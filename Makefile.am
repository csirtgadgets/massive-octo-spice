SUBDIRS = es 
EXTRA_DIST = smrt router sbin contrib cpanfile libcif

PERLOPTS=DESTDIR=$(DESTDIR) INSTALL_BASE=$(CIF_PATH) INSTALLPRIVLIB=${siteperldir}
PERL_INSTALLOPTS=INSTALL="$(INSTALL)" sysconfdir=$(sysconfdir) localstatedir=$(localstatedir) CIF_USER=$(CIF_USER) CIF_GROUP=$(CIF_GROUP)

# http://stackoverflow.com/questions/3931741/why-does-make-think-the-target-is-up-to-date
.PHONY: libcif smrt router

all: default
default: libcif smrt router
test: libcif-test smrt-test router-test
install: libcif-install router-install smrt-install install-var
fixperms: smrt-fixperms var-fixperms

install-var:
	[ -d $(DESTDIR)$(localstatedir) ] || $(INSTALL) -m 0770 -d $(DESTDIR)$(localstatedir)

var-fixperms:
	chown -R $(CIF_USER):$(CIF_GROUP) $(DESTDIR)$(localstatedir)

libcif: libcif-geoip
	( cd libcif && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

libcif-test:
	( cd libcif && CRITIC=$(PERL_CRITIC) make test )

libcif-install: libcif-install-files libcif-install-geoip

libcif-install-files:
	( cd libcif && make install )

libcif-geoip:
if HAVE_GEOIP
	if [ ! -f libcif/contrib/GeoLite2-City.mmdb ]; then \
		$(CURL) http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -o libcif/contrib/GeoLite2-City.mmdb.gz; \
		$(GZIP) -d libcif/contrib/GeoLite2-City.mmdb.gz; \
	else \
		echo 'libcif/contrib/GeoLite2-City.mmdb already exists... skipping.'; \
	fi;
else
	@echo 'geoip not enabled, skipping...'
endif

libcif-install-geoip:
if HAVE_GEOIP
	( cd libcif && make install-geoip $(PERL_INSTALLOPTS) )
else
	@echo 'geoip not enabled, skipping...'
endif

smrt:
	( cd smrt && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

smrt-test:
	(cd smrt && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

smrt-install:
	( cd smrt && make install && make install-rules $(PERL_INSTALLOPTS) )

smrt-fixperms:
	( cd smrt && make fixperms $(PERL_INSTALLOPTS) )

router:
	( cd router && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

router-test:
	( cd router && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

router-install:
	( cd router && make install)

router-fixperms:
	( cd router && make fixperms $(PERL_INSTALLOPTS) )

deps:
if HAVE_CPANM
	$(CPANM) $(NOTESTS) --installdeps ./libcif
	$(CPANM) $(NOTESTS) --installdeps ./smrt
	$(CPANM) $(NOTESTS) --installdeps ./router
else
	@echo "missing App::cpanminus, please install with \"perl -MCPAN -e 'install App::cpanminus'\" and re-run ./configure"
	exit -1
endif
	
es-init:
	( cd es && make init )

es-deinit:
	( cd es && make deinit )

es-reload:
	(cd es && make reload )

clean:
	find . -name 'MANIFEST' -delete
	find . -name 'MANIFEST.bak' -delete
	( cd libcif && $(PERL) Makefile.PL && make realclean )
	( cd smrt && $(PERL) Makefile.PL && make realclean )
	( cd router && $(PERL) Makefile.PL && make realclean )

reconf:
	autoreconf -vf

dist-hook:
	rm -rf $(distdir)/libcif/blib
	find $(distdir) -name "*.gz" -delete
	find $(distdir) -name "*.mmdb" -delete
	rm -rf $(distdir)/smrt/blib
	rm -rf $(distdir)/router/blib
	find $(distdir)/smrt/testdata -name '*.log' -delete
	find $(distdir) -name 'Makefile' -delete
	find $(distdir) -name 'pm_to_blib' -delete
	find $(distdir) -name 'CIF-.tar.gz' -delete
	find $(distdir) -name '*.old' -delete
	find $(distdir) -name '*.bak' -delete
	find $(distdir) -name '.DS_Store' -delete
