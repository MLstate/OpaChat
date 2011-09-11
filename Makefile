S = @ # silent

.PHONY: all clean run $(EXE)

OPA ?= opa
MINIMAL_VERSION = 60
EXE = opa_chat.exe

all: $(EXE)

$(EXE): src/*.opa resources/*
	$(OPA) --minimal-version $(MINIMAL_VERSION) src/main.opa -o $(EXE)

run: all
	$(S) ./$(EXE) || exit 0 ## prevent ugly make error 130 :) ##

clean:
	rm -Rf *.exe _build _tracks *.log **/#*#
