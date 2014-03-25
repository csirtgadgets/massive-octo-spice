CURLOPTS=-w "\n"
CURL=/usr/bin/curl $(CURLOPTS)
HOST=http://localhost:9200
MAPPING=map.json
INDEX=cif

all-am: default
default:

initdb:
	$(CURL) -XPUT $(HOST)/$(INDEX) -d @$(MAPPING)

removedb:
	$(CURL) -XDELETE $(HOST)/$(INDEX) -w "\n"

reloaddb: removedb initdb

list:
	$(CURL) -XGET $(HOST)/$(INDEX)/_mapping?pretty -w "\n"
