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

install: base-install config-install contrib-install

base-install:
	[ -d "$(DESTDIR)$(CIF_PATH)/kibana" ] || $(INSTALL) -m 0750 -d $(DESTDIR)$(CIF_PATH)/kibana
	[ -d "$(DESTDIR)$(CIF_PATH)/kibana/www" ] || $(INSTALL) -m 0755 -d $(DESTDIR)$(CIF_PATH)/kibana/www
	tar -pzxvf $(FILE) -C "$(DESTDIR)$(CIF_PATH)/kibana/www" --strip 1

contrib-install:
	-( cd contrib && find . -type f -print | grep -v ".in$$" ) | while read file ; do \
        $(INSTALL) -m 0660 "contrib/$$file" "$(DESTDIR)$(CIF_PATH)/contrib/$$file" ; \
    done

config-install:
	cp $(DESTDIR)$(CIF_PATH)/kibana/www/app/dashboards/default.json $(DESTDIR)$(CIF_PATH)/kibana/www/app/dashboards/default.json.orig
	$(INSTALL) -m 664 "dashboard.json" $(DESTDIR)$(CIF_PATH)/kibana/www/app/dashboards/default.json
