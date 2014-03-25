EXTRA_DIST = \
    kibana-3.0.0.tar.gz \
    kibana-3.0.0.tar.gz.asc \
    contrib

BASE_URL = https://download.elasticsearch.org/kibana/kibana/
FILE = kibana-3.0.0.tar.gz
HASHFILE = "$(FILE).asc"

all-am:

build:
	[ -e $(FILE) ] || $(WGET) $(BASE_URL)/$(FILE)
	[ "$(shell $(SHA1SUM) -c $(FILE).asc)"="$(FILE): OK" ] 

install: base-install config-install

base-install:
	[ -d "$(CIF_PATH)/kibana" ] || $(INSTALL) -m 0755 -d $(CIF_PATH)/kibana
	tar -zxvf $(FILE) -C "$(CIF_PATH)/kibana" --strip 1
