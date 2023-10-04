#include "kernel/types.h"
#include "user/user.h"
#include <stddef.h>

int main(int argc, char **argv) {
int currTime,pid;
currTime = uptime();
pid = fork();
if(pid==0){ // Lazy way if child, move arguments and execute
	argv[0]=argv[1];
        argv[1] = argv[2];
        argv[2]=NULL;
        exec(argv[0],argv);
}
else if(pid>0){
wait(NULL); //Parent waits for child to finish
printf("elasped time: %d \n",uptime()-currTime);
}
else{
	printf("Fork failed Yo");
}
exit(0);
}
