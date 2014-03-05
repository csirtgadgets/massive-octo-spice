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
	echo "FIXME!!!!"

rules-install2:
	[ -d $(CIF_PATH)/$(sysconfdir) ] || $(INSTALL) -m 0755 -d $(CIF_PATH)/$(sysconfdir)
	-( cd rules && find . -type d -print ) | while read dir ; do \
    $(INSTALL) -m 0750 -d "$(CIF_PATH)/$(sysconfdir)/$$dir" ; \
    done
	-( cd rules && find . -type f -print ) | while read file ; do \
    $(INSTALL) -m 0640 "rules/$$file" "$(CIF_PATH)/$(sysconfdir)/$$file" ; \
    done

libs-install:
	[ -d $(CIF_PATH)/$(libdir) ] || $(INSTALL) -m 0755 -d $(CIF_PATH)/$(libdir)
	-( cd lib && find . -type d -print ) | while read dir ; do \
    $(INSTALL) -m 0755 -d "$(CIF_PATH)/$(libdir)/$$dir" ; \
    done
	-( cd lib && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
    $(INSTALL) -m 0644 "lib/$$file" "$(CIF_PATH)/$(libdir)/$$file" ; \
    done
    
bin-install:    
	[ -d $(CIF_PATH)/$(bindir) ] || $(INSTALL) -m 0755 -d $(CIF_PATH)/$(bindir)
	-( cd bin && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
        $(INSTALL) -m 0755 "bin/$$file" "$(CIF_PATH)/$(bindir)/$$file" ; \
    done
