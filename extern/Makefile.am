SUBDIRS = elasticsearch kibana

all-am: default
default: 

if HAVE_EMBEDDED
install: install-es install-kibana
else
install:
endif

install-es:
	( cd elasticsearch && make install )

install-kibana:
	( cd kibana && make install )
