EXTRA_DIST = lib bin rules testdata t

TEST_FILES=t/00*.t
TEST_VERBOSE=0
LIBS=../libcif/lib,lib

all-am: default
default:

test: 
	$(PERL) "-MExtUtils::Command::MM" -e "test_harness($(TEST_VERBOSE), split(/,/,'$(LIBS)'))" $(TEST_FILES)

install: libs-install bin-install rules-install 

local-whitelist:
	[ -e $(CIF_PATH)/local/etc/whitelist_domains ] || touch "$(CIF_PATH)/local/etc/whitelist_domains"
	[ -e $(CIF_PATH)/local/etc/whitelist_infrastructure ] || touch "$(CIF_PATH)/local/etc/whitelist_infrastructure"
	[ -e $(CIF_PATH)/local/etc/whitelist_urls ] || touch "$(CIF_PATH)/local/etc/whitelist_urls"

rules-install:
	[ -d $(DESTDIR)$(CIF_PATH)/$(sysconfdir)/rules ] || $(INSTALL) -m 0755 -d $(DESTDIR)$(CIF_PATH)/$(sysconfdir)/rules
	-( cd rules && find . -type d -print ) | while read dir ; do \
    $(INSTALL) -m 0750 -d "$(DESTDIR)$(CIF_PATH)/$(sysconfdir)/rules/$$dir" ; \
    done
	-( cd rules && find . -type f -print ) | while read file ; do \
    $(INSTALL) -m 0640 "rules/$$file" "$(DESTDIR)$(CIF_PATH)/$(sysconfdir)/rules/$$file" ; \
    done

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
