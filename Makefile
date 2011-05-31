all: opa_chat.exe

bindings: bsl/rusage.c
	cd bsl && ocamlc rusage.c -o rusage.o
	cd bsl && opa-plugin-builder c_binding.ml -o c_binding

opa_chat.exe: bindings src/main.opa
	opa --mllopt $(PWD)/bsl/rusage.o bsl/c_binding.opp src/main.opa -o opa_chat.exe

clean:
	\rm -Rf bsl/*.opp bsl/*.o
	\rm -Rf *.exe _build _tracks *.log
