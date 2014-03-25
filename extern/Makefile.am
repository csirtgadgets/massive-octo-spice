SUBDIRS = elasticsearch kibana

all-am: default
default: 

test:

install: install-es install-kibana

install-es:
	( cd elasticsearch && make install )

install-kibana:
	( cd kibana && make install )
