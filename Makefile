S = @ # silent

.PHONY: all clean run $(EXE)

OPA ?= opa
OPA_OPT ?= --parser js-like
MINIMAL_VERSION = 1046
EXE = opa_chat.exe

all: $(EXE)

plugins: plugins/file/file.js
	opa-plugin-builder --js-validator-off plugins/file/file.js -o file.opp
	$(OPA) $(OPA_OPT) plugins/file/file.opa file.opp

$(EXE): plugins src/*.opa resources/*
	$(OPA) $(OPA_OPT) --minimal-version $(MINIMAL_VERSION) *.opp src/*.opa -o $(EXE)

run: all
	$(S) ./$(EXE) $(RUN_OPT) || exit 0 ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.opx* *.opp*
	rm -Rf *.exe _build _tracks *.log **/#*#
