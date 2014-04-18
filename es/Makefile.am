CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
MAPPING=map.json
INDEX=cif
INDICIES=cif-*

all-am: default
default:

init:
	$(CURLCMD) -XPUT $(HOST)/$(INDEX) -d @$(MAPPING)

deinit:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"
	$(CURLCMD) -XDELETE $(HOST)/$(INDEX) -w "\n"

reload: init deinit 

list:
	$(CURLCMD) -XGET $(HOST)/$(INDEX)/_mapping?pretty -w "\n"
