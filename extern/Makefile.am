SUBDIRS = elasticsearch
EXTRA_DIST = \
    Config-Simple-4.59

EXTERN_PERL = \
	Config-Simple-4.59

all-am: default
default: build

build: build_perl 
test: test_perl

install: install_perl install-es

install-es:
	-( cd elasticsearch && make install )

build_perl:
	for file in $(EXTERN_PERL) ; do \
		cd $$file && $(PERL) Makefile.PL; \
	done

test_perl:
	for file in $(EXTERN_PERL) ; do \
		cd $$file && make test; \
	done

install_perl:
	for file in $(EXTERN_PERL) ; do \
    	cd $$file && make install; \
	done
