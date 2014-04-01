EXTRA_DIST = lib sbin bin contrib t config.layout .deps

TEST_FILES=t/00-*.t t/10-*.t
TEST_VERBOSE=0
LIBS=lib

all-am: default

default: 

fixdeps:
	$(PERL) ./sbin/test-deps --verbose --install

testdeps:
	$(PERL) ./sbin/test-deps --verbose

test:
	$(PERL) "-MExtUtils::Command::MM" -e "test_harness($(TEST_VERBOSE), split(/,/,'$(LIBS)'))" $(TEST_FILES)

install: libs-install bin-install fix-perms

libs-install:
	[ -d $(DESTDIR)$(CIF_PATH)/$(libdir) ] || $(INSTALL) -m 0755 -d $(DESTDIR)$(CIF_PATH)/$(libdir)
	-( cd lib && find . -type d -print ) | while read dir ; do \
    $(INSTALL) -m 0755 -d "$(DESTDIR)$(CIF_PATH)/$(libdir)/$$dir" ; \
    done
	-( cd lib && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
    $(INSTALL) -m 0644 "lib/$$file" "$(DESTDIR)$(CIF_PATH)/$(libdir)/$$file" ; \
    done

bin-install:    
	[ -d $(DESTDIR)$(CIF_PATH)/$(bindir) ] || $(INSTALL) -m 0755 -d $(DESTDIR)$(CIF_PATH)/$(bindir)
	-( cd bin && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
        $(INSTALL) -m 0755 "bin/$$file" "$(DESTDIR)$(CIF_PATH)/$(bindir)/$$file" ; \
    done

fix-perms:
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
