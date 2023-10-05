#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


void
main(void)
{
  printf("up %d clock ticks \n",uptime());
  exit(0);
}
