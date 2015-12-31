EXTRA_DIST = observables.json tokens.json

CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=observables.json tokens.json
INDICIES=cif.*

all-am: default
default:
	@echo 'nothing to do'
	
init:
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_observables/' -d @observables.json
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_tokens/' -d @tokens.json

remove:
	$(CURLCMD) -XDELETE $(HOST)/cif.* -w "\n"

remove-data:
	$(CURLCMD) -XDELETE $(HOST)/cif.observables-* -w "\n"

reload: remove init

reload-data: remove-data
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_observables/' -d @observables.json

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"

remove-templates:
	$(CURLCMD) -XDELETE $(HOST)/_template/template_cif_observables
	$(CURLCMD) -XDELETE $(HOST)/_template/template_cif_tokens
