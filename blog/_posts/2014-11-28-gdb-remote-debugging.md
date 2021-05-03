---
layout: post
title: 'GDB Remote Debugging'
category: memo
slug: gdb-remote-debugging
---

Sometimes we want to debug a program which acts interactively with user. It is
a bad idea to debug this kind of program with normal gdb and nc command. This
article provides an alternative way to debug the program remotely.

On the target machine, you need to have a copy of the program you want to debug.
But actually the symbol table of the program does not needed by gdbserver. The
gdb on the host does all the symbol handling.

To use the gdbserver, you must tell it how to communicate with gdb, the program
being debugged, and the arguments for the program:

```bash
target> gdbserver <comm> <program> [ args ... ]
```

Using `ncat` to concatenate and redirect socket for the program. The below
example shows that the use of `ncat` along with `gdbserver`. You must use
the same debug port for the `target remote` command on the host machine.

```bash
target> ncat -vc "gdbserver <host>:<debug-port> <program>" -kl <listen-port>
```

On the gdb host machine, you need an unstripped copy of your program because gdb
needs symbol and debugging information.

```bash
$ gdb <program>
(gdb) target remote <target>:<debug-port>
```

Then you can use any client (nc, curl, telnet..., etc.) to connect with the
server on which gdb debugs. For example:

```bash
$ curl -v http://<target>:<port>
...
$ nc <target> <port>
```

## Reference

- [Debugging with GDB: Remote Debugging](http://davis.lbl.gov/Manuals/GDB/gdb_17.html)
