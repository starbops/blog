---
title: Network Programming 2014-09-25
category: note
slug: network-programming-20140925
date: 2014-09-25
---
2014/09/25 Network Programming Class Note

## Memory

```text
User Context
+----------------+
| stack
+----------------+
|
+----------------+
| heap
+----------------+
| uninitialized data
+----------------+
| initialized
| read-write
| data
+----------------+
|
+----------------+
|
+----------------+
|
+----------------+
```

## Arguments

-  argv's last element "points" to null (?)
-  envp

## Users and Groups

### Effective User ID

-  elevate privilege temporarily
-  `seteuid()`, e.g. `/usr/bin/passwd`

## System Call

-  system call: trap
-  library function: pointer
-  無法 set break point at system call (?)
-  Use system call frequently may cause performance of the program degrade
   significantly, unlike library function call

## File Model in Unix

-  discriptor table: one per process

```text
Process
FD Table
+---------+
| stdin   | -------> +---------+
+---------+          | console |
| stdout  |          +---------+
+---------+
| stderr  |
+---------+
| file... | -------> +-----------+ -------> +------+
+---------+          | file      |          | file |
| file... |          | internal  |          +------+
+---------+          | structure |
| ...     |          +-----------+
+---------+
```

-  File internal structure 包含檔案讀到哪裡的 pointer, etc.
-  start over

## Signal Model

-  `kill(int pid, int sig)`: conceptually is "signal" we learned
-  `signal(int sig,, void (*func)(int))`: setting signal handler

### Being Interrupt while Handling a Signal

Old

```text
|  ^  ^
| /| /|
|/ v/ |
|\    |
| \   v
|  \  |
|   \_|
|
v
```

New: concatenate

### Pause

-  The `sigblock()` and `sigsetmask()` functions return the previous set of
   masked signals
-  sigpause()

## Fork

-  Child process has
   -  A new pid
   -  A different parent pid
   -  A copy of parent's FD table
      -  **does not copy file internal structure**
      -  若 parent 有 read file，child 會接著目前 pointer 讀下去
      -  Solution: close file, only one open left

-  `fork()` return value
   -  child: 0
   -  parent: child's pid
   -  error: -1
