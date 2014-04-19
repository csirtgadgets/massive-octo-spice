SUBDIRS = es 
EXTRA_DIST = smrt router sbin contrib cpanfile libcif

PERLOPTS=DESTDIR=$(DESTDIR) INSTALL_BASE=$(CIF_PATH) INSTALLPRIVLIB=${siteperldir}

# http://stackoverflow.com/questions/3931741/why-does-make-think-the-target-is-up-to-date
.PHONY: libcif smrt router

all: default
default: libcif smrt router
test: libcif-test smrt-test router-test
install: libcif-install router-install smrt-install install-var
fix-perms: smrt-fix-perms var-fix-perms

install-var:
	[ -d $(DESTDIR)$(localstatedir) ] || $(INSTALL) -m 0770 -d $(DESTDIR)$(localstatedir)

var-fix-perms:
	chown -R $(CIF_USER):$(CIF_GROUP) $(DESTDIR)$(localstatedir)

libcif:
	( cd libcif && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

libcif-test:
	( cd libcif && CRITIC=$(PERL_CRITIC) make test )

libcif-install:
	( cd libcif && make install )

smrt:
	( cd smrt && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

smrt-test:
	(cd smrt && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

smrt-install:
	( cd smrt && make install && make install-rules INSTALL="$(INSTALL)" sysconfdir=$(sysconfdir) CIF_USER=$(CIF_USER) CIF_GROUP=$(CIF_GROUP) )

smrt-fix-perms:
	( cd smrt && make fix-perms sysconfdir=$(sysconfdir) CIF_USER=$(CIF_USER) CIF_GROUP=$(CIF_GROUP) )

router:
	( cd router && $(PERL) Makefile.PL && make manifest && $(PERL) Makefile.PL $(PERLOPTS) && make )

router-test:
	( cd router && PERL5LIB=../libcif/lib CRITIC=$(PERL_CRITIC) make test )

router-install:
	( cd router && make install)

router-fix-perms:
	( cd router && make fix-perms sysconfdir=$(sysconfdir) localstatedir=$(localstatedir) CIF_USER=$(CIF_USER) CIF_GROUP=$(CIF_GROUP) )

deps:
if HAVE_CPANM
	$(CPANM) $(NOTESTS) --installdeps ./libcif
	$(CPANM) $(NOTESTS) --installdeps ./smrt
	$(CPANM) $(NOTESTS) --installdeps ./router
else
	@echo "missing App::cpanminus, please install with \"perl -MCPAN -e 'install App::cpanminus'\" and re-run ./configure"
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
