SUBDIRS = es
EXTRA_DIST = contrib cpanfile src 

PERLOPTS=DESTDIR=$(DESTDIR) INSTALL_BASE=$(CIF_PATH) INSTALLPRIVLIB=${siteperldir}
PERL_INSTALLOPTS=INSTALL="$(INSTALL)" sysconfdir=$(sysconfdir) localstatedir=$(localstatedir) CIF_USER=$(CIF_USER) CIF_GROUP=$(CIF_GROUP)
CPANMOPTS=-n

.PHONY: src

all: default
default:
	( cd src && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

test:
	( cd src && CRITIC=$(PERL_CRITIC) make test )

deps: geoip
if HAVE_CPANM
	$(CPANM) $(CPANMOPTS) --installdeps ./src
else
	@echo "missing App::cpanminus, please install with \"perl -MCPAN -e 'install App::cpanminus'\" and re-run ./configure"
	exit -1
endif

geoip:
if HAVE_GEOIP
	if [ ! -f contrib/GeoLite2-City.mmdb ]; then \
		$(CURL) http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz -o contrib/GeoLite2-City.mmdb.gz; \
		$(GZIP) -d contrib/GeoLite2-City.mmdb.gz; \
	else \
		echo 'contrib/GeoLite2-City.mmdb already exists... skipping.'; \
	fi;
else
	@echo 'geoip not enabled, skipping...'
endif

install: install-files install-rules install-var install-geoip

install-geoip:
if HAVE_GEOIP
	$(INSTALL) -m 660 "contrib/GeoLite2-City.mmdb" "$(DESTDIR)$(localstatedir)/GeoLite2-City.mmdb"
else
	@echo 'geoip not enabled, skipping...'
endif

install-files:
	( cd src && make install )

install-rules:
	[ -d $(DESTDIR)$(sysconfdir)/rules ] || $(INSTALL) -m 0770 -d $(DESTDIR)$(sysconfdir)/rules
	-( cd src/rules && find . -type d -print ) | while read dir ; do \
		$(INSTALL) -m 0770 -d "$(DESTDIR)$(sysconfdir)/rules/$$dir" ; \
	done
	-( cd src/rules && find . -type f -print ) | while read file ; do \
		$(INSTALL) -m 0660 "src/rules/$$file" "$(DESTDIR)$(sysconfdir)/rules/$$file" ; \
	done

install-var:
	[ -d $(DESTDIR)$(localstatedir) ] || $(INSTALL) -m 0770 -d $(DESTDIR)$(localstatedir)

fixperms: fixperms-var fixperms-rules

fixperms-var:
	chmod 0770 $(DESTDIR)$(localstatedir)
	chown -R $(CIF_USER) $(DESTDIR)$(localstatedir)
	chgrp -R $(CIF_GROUP) $(DESTDIR)$(localstatedir)
	
fixperms-rules:
	chmod 0770 $(DESTDIR)$(sysconfdir)/rules
	chown -R $(CIF_USER) $(DESTDIR)$(sysconfdir)/rules
	chgrp -R $(CIF_GROUP) $(DESTDIR)$(sysconfdir)/rules

clean-local:
	find . -name '*.log' -delete
	
es-init:
	( cd es && make init )

es-deinit:
	( cd es && make deinit )

es-reload:
	(cd es && make reload )

clean:
	find . -name 'MANIFEST' -delete
	find . -name 'MANIFEST.bak' -delete
	( cd src && $(PERL) Makefile.PL && make realclean )

reconf:
	autoreconf -vf

dist-hook:
	sh ./version.sh > $(distdir)/.version
	rm -rf $(distdir)/src/blib
	find $(distdir) -name "*.gz" -delete
	find $(distdir) -name "*.mmdb" -delete
	find $(distdir)/src/testdata -name '*.log' -delete
	find $(distdir) -name 'Makefile' -delete
	find $(distdir) -name 'pm_to_blib' -delete
	find $(distdir) -name 'CIF-.tar.gz' -delete
	find $(distdir) -name '*.old' -delete
	find $(distdir) -name '*.bak' -delete
	find $(distdir) -name '.DS_Store' -delete
