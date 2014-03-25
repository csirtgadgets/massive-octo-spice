EXTRA_DIST = \
    elasticsearch.yml.in \
    elasticsearch-1.0.1.tar.gz \
    elasticsearch-1.0.1.tar.gz.asc

ES_BASE_URL = https://download.elasticsearch.org/elasticsearch/elasticsearch
ES = elasticsearch-1.0.1.tar.gz
HASHFILE = "$(ES).asc"

## TODO
#ERR_HASH = $(error sha1sum mis-match, possible file corruption...)

FILES = \
	elasticsearch.yml

all-am:

build:
	[ -e $(ES) ] || $(WGET) $(ES_BASE_URL)/$(ES)
	[ "$(shell $(SHA1SUM) -c $(ES).asc)"="$(ES): OK" ] 

install: base-install config-install

base-install:
	[ -d "$(CIF_PATH)/elasticsearch" ] || $(INSTALL) -m 0755 -d $(CIF_PATH)/elasticsearch
	tar -zxvf $(ES) -C "$(CIF_PATH)/elasticsearch" --strip 1

config-install:
	for file in $(FILES) ; do \
		$(INSTALL) -m 0640 "$$file" "$(CIF_PATH)/elasticsearch/config/$$file" ; \
	done
