#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/pstat.h"
#include "user/user.h"

int
main(int argc, char **argv)
{
  struct pstat uproc[NPROC];
  int nprocs;
  int i;
  int lifeTime;
  char *state;
  static char *states[] = {
    [SLEEPING]  "sleeping",
    [RUNNABLE]  "runnable",
    [RUNNING]   "running ",
    [ZOMBIE]    "zombie  "
  };

  nprocs = getprocs(uproc);
  if (nprocs < 0)
    exit(-1);

  printf("pid\tstate\t\tsize\tppid\tname\tpriority\tlifetime\n");
  for (i=0; i<nprocs; i++) {
    state = states[uproc[i].state];
    lifeTime = uproc[i].readytime;
    printf("%d\t%s\t%l\t%d\t%s\t%d\t\t%d\n", uproc[i].pid, state,
                   uproc[i].size, uproc[i].ppid, uproc[i].name, uproc[i].priority,uptime()-lifeTime);
  }

  exit(0);
}

