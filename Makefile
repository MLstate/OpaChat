.PHONY: all clean run plugins $(EXE)

OPA ?= opa
OPA_PLUGIN ?= opa-plugin-builder
OPA_OPT ?= --parser js-like --back-end qmljs
RUN_OPT ?= --db-remote:opa_chat localhost:27017 --db-remote:opa_share localhost:27017
MINIMAL_VERSION = 1900
EXE = opa_chat.js

all: $(EXE)

plugins: plugins/file/file.js
	$(OPA_PLUGIN) --js-validator-off plugins/file/file.js -o file.opp
	$(OPA) $(OPA_OPT) -c plugins/file/file.opa file.opp

$(EXE): plugins src/*.opa resources/*
	$(OPA) $(OPA_OPT) --minimal-version $(MINIMAL_VERSION) *.opp src/*.opa -o $(EXE)

run: all
	node $(EXE) $(RUN_OPT) || true ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.opx* *.opp*
	rm -Rf *.exe _build _tracks *.log **/#*#
