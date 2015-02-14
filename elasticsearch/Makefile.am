EXTRA_DIST = observables.json feeds.json tokens.json

CURLOPTS=-w "\n"
CURLCMD=$(CURL) $(CURLOPTS)
HOST=http://$(ES_HOST)
TEMPLATE=observables.json feeds.json tokens.json
INDICIES=cif.*

all-am: default
default:
	@echo 'nothing to do'
	
init:
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_observables/' -d @observables.json
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_feeds/' -d @feeds.json
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_tokens/' -d @tokens.json

remove:
	$(CURLCMD) -XDELETE $(HOST)/cif.* -w "\n"

remove-data:
	$(CURLCMD) -XDELETE $(HOST)/cif.observables-* -w "\n"
	$(CURLCMD) -XDELETE $(HOST)/cif.feeds-* -w "\n"

reload: remove init

reload-data: remove-data
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_observables/' -d @observables.json
	$(CURLCMD) -XPUT '$(HOST)/_template/cif_feeds/' -d @feeds.json

list:
	$(CURLCMD) -XGET $(HOST)/$(INDICIES)/_mapping?pretty -w "\n"