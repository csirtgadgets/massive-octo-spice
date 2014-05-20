CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=cif-template.json
INDEX=cif
INDICIES=cif-*

all-am: default
default:
	$(CURLCMD) -XPUT '$(HOST)/_template/template_cif/' -d @$(TEMPLATE)

remove:
	$(CURLCMD) -XDELETE $(HOST)/$(INDICIES) -w "\n"

reload: remove default

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"
