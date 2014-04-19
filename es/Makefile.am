CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=cif-template.json
INDEX=cif
INDICIES=cif-*

all-am: default
default:

init:
	$(CURLCMD) -XPUT '$(HOST)/_template/template_cif/' -d @$(TEMPLATE)

deinit:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"

reload: init deinit 

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"
