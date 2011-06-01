#include <stdlib.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

long usage() {
  int who = RUSAGE_SELF;
  struct rusage usage;
  struct rusage *p = &usage;
  getrusage(who, p);
  return p->ru_maxrss;
}

#include <errno.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/compatibility.h>
#include <caml/fail.h>

value get_memory_usage() {
  CAMLparam0();
  CAMLreturn(Val_long(usage()));
}
