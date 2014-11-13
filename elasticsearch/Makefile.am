EXTRA_DIST = map.json

CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=map.json
INDICIES=cif.*-*
INDICIES_ALL=cif.*

all-am: default
default:
	@echo 'nothing to do'
	
init:
	$(CURLCMD) -XPUT '$(HOST)/_template/template_cif/' -d @$(TEMPLATE)

remove:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES_ALL) -w "\n"

remove-data:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"

reload: remove init
reload-data: remove-data init

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"
