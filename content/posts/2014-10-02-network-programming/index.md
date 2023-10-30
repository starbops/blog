---
title: Network Programming 2014-10-02
category: note
slug: network-programming-20141002
date: 2014-10-02
---
2014/10/02 Network Programming Class Note

## exec()

-  `exec()` does not create new PID, only `fork()` spawn new PID
-  loader
-  does not change FD table
-  ex: `execl("ls", "ls", "-la", "d1")`

## exit()

-  `exit()` has an argument that means error code, to parent
-  flush the buffer before exit

## wait()

-  parent process use `wait(child_pid)` to wait for child process ends
-  exit status is read via `wait()` system call

## PID Table

-  PID table: round-robin
-  1 -> 2 -> ... -> 65535 -> 1 (if available)
-  process fork flow:
   -  parent `fork()` child, child `exec()` to load some other program
   -  parent `wait()` while child `exit()`, then read the exit status of
      child.
   -  the child's pid in PID table will be freed
-  zombie process: parent does not `wait()` for child, i.e. the exit status
   is not read via parent's `wait()` system call when child is in terminated
   state but still has an entry in process table.
-  orphan process: child's parent process has finished or terminated, but it
   remains running itself.

## File Locking

-  Context-switch's atomic unit is assembly instruction
-  The `FILE` structure has a buffer

## Buffering for printf

Consider the following C code

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void err_sys(const char* x)
{
    perror(x);
    exit(1);
}

int main(void) {
    int pipefd[2], n;
    char buff[100];

    if(pipe(pipefd) < 0)
        err_sys("pipe error");

    printf("read fd = %d, write fd = %d\n", pipefd[0], pipefd[1]);
    if(write(pipefd[1], "hello world\n", 12) != 12)
        err_sys("write error");

    if((n = read(pipefd[0], buff, sizeof(buff))) <=0)
        err_sys("read error");

    write(1, buff, n);

    exit(0);
}
```

The output will be (assume you redirect the output into a file)

```text
hello world
read fd = 3, write fd = 4
```

The output's order was odd, but there are reasons. The main concept is
"buffering". `printf()` will buffer the strings you want to print. It does
not sent the strings to the device, say `stdout`, immediately. Because
`printf()` is a library call not a system call. If you use `write()` system
call instead, the string "hello world\n" will not be buffered. The string will
be sent to the device as soon as possible.

The buffer will be flushed when:

-  The buffer is full
-  `flush()` is called (maybe `fflush()` ?)
-  `exit()` is called

Even though the key concept is buffering, there are still some tiny rules
affect the facts. For example, when console output is used, output to device
will be done in no time with the following two cases:

-  Linefeed, i.e. "\n"
-  The program attempts to read from the terminal (?)

Reminder: **Do not use `printf()` for heavy interaction**

`_Exit()` is more brutal than `exit()`. If you try to redirect the output
into a file, the strings stored in the buffer will not be shown. `_Exit()`
terminate the process in no time, and it will not sent the strings which are
still in the buffer to the output.
