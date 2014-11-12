EXTRA_DIST = map.json

CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=map.json
INDICIES=cif.*-*

all-am: default
default:
	@echo 'nothing to do'
	
init:
	$(CURLCMD) -XPUT '$(HOST)/_template/template_cif/' -d @$(TEMPLATE)

remove:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"

reload: remove init

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"
