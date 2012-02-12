S = @ # silent

.PHONY: all clean run $(EXE)

OPA ?= opa
MINIMAL_VERSION = 1046
EXE = opa_chat.exe

all: $(EXE)

$(EXE): src/*.opa resources/*
	$(OPA) --parser js-like --minimal-version $(MINIMAL_VERSION) src/main.opa -o $(EXE)

run: all
	$(S) ./$(EXE) $(RUN_OPT) || exit 0 ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.exe _build _tracks *.log **/#*#
