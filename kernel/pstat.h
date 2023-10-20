struct pstat {
  int pid;     // Process ID
  enum procstate state;  // Process state
  uint64 size;     // Size of process memory (bytes)
  int ppid;        // Parent process ID
  char name[16];
  int priority;   // Parent command name
  int readytime;
};
struct rusage {
uint cputime;
};
struct ruprio {
uint priority;
};
