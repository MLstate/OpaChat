.PHONY: all clean run plugins $(EXE)

OPA ?= opa
OPA_OPT ?= --js-bypass-syntax jsdoc
RUN_OPT ?= --db-remote:opa_chat localhost:27017 --db-remote:opa_share localhost:27017
MINIMAL_VERSION = 4051
EXE = opa_chat.js

all: $(EXE)

$(EXE): plugins/file/file.opa plugins/file/file.js src/*.opa resources/*
	$(OPA) $(OPA_OPT) --minimal-version $(MINIMAL_VERSION) src/*.opa \
	plugins/file/file.opa plugins/file/file.js -o $(EXE)

release:
	zip -r chat.zip _build file.opx opa_chat.js

run: all
	./$(EXE) $(RUN_OPT) || true ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.opx* *.opp*
	rm -Rf *.exe _build _tracks *.log **/#*#
	rm -Rf opa_chat_depends opa_chat.js
