#include <sys/resource.h>

long usage() {
  int who = RUSAGE_SELF;
  struct rusage usage;
  struct rusage *p = &usage;
  getrusage(who, p);
  return p->ru_maxrss;
}

#include <caml/memory.h>

value get_memory_usage() {
  CAMLparam0();
  CAMLreturn(Val_long(usage()));
}
