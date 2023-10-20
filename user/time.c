#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
#include "kernel/pstat.h"
#include <stddef.h>

int main(int argc, char **argv) {
int currTime,pid,totalTime;
struct rusage cptime;

currTime = uptime();
pid = fork();
if(pid==0){ // Lazy way to get proper argument from time/time1
	argv[0]=argv[1];
        argv[1] = argv[2];
        argv[2]=NULL;
        exec(argv[0],argv);
}
else if(pid>0){
wait2(0,&cptime);
totalTime = uptime()-currTime;
printf("elasped time: %d \n",totalTime);
printf("CPU TIME:%d ",cptime.cputime);
printf("TICKS,CPU PERCENTAGE: %d%\n",cptime.cputime*100/totalTime);
}
else{
	printf("Fork failed Yo");
}
exit(0);
}
