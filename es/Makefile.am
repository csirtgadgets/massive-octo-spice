CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
MAPPING=map.json
INDEX=cif
INDICIES=cif-*

all-am: default
default:

initdb:
	$(CURLCMD) -XPUT $(HOST)/$(INDEX) -d @$(MAPPING)

dropdb:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"
	$(CURLCMD) -XDELETE $(HOST)/$(INDEX) -w "\n"

reloaddb: dropdb initdb

list:
	$(CURLCMD) -XGET $(HOST)/$(INDEX)/_mapping?pretty -w "\n"
