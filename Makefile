OPA = /opt/mlstate/bin/opa
MINIMAL_VERSION = 60

all: opa_chat.exe

opa_chat.exe: src/main.opa
	$(OPA) --minimal-version $(MINIMAL_VERSION) src/main.opa -o opa_chat.exe

clean:
	\rm -Rf bsl/*.opp bsl/*.o
	\rm -Rf *.exe _build _tracks *.log
