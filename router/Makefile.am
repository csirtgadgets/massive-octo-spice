EXTRA_DIST = lib bin t

TEST_FILES=t/00*.t t/10-*.t
TEST_VERBOSE=0
LIBS=../libcif/lib,lib

all-am: default
default:

test: 
	$(PERL) "-MExtUtils::Command::MM" -e "test_harness($(TEST_VERBOSE), split(/,/,'$(LIBS)'))" $(TEST_FILES)

install: libs-install bin-install 

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
