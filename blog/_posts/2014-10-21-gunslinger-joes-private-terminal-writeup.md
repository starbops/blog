---
layout: post
title: 'Hack.lu CTF 2014: Gunslinger Joe’s private Terminal Writeup'
category: memo
slug: gunslinger-joes-private-terminal-writeup
---
First time of my life I solved a problem in a real CTF! Though it is a pretty
easy one, it means something to me.

## Problem Description

In the Hack.lu CTF website, there are some description about "Gunslinger Joe's
private Terminal":

```text
Gunslinger Joe's private Terminal
by cutz (Misc)
50 (+20) Points
Gunslinger Joe has a pretty bad memory and always forgets the password for his
private terminals! That's why he always uses his username as password but also
makes sure that absolutely no one else who knows his name can interact with his
secure terminal. Wouldn't it be super embarrassing for him to prove him wrong?

SSH: gunslinger_joe@wildwildweb.fluxfingers.net
PORT: 1403
```

According to the description above, Gunslinger Joe's SSH account and password
are both "gunslinger_joe". So let's connect to the SSH server:

```bash
$ ssh wildwildweb.fluxfingers.net -l gunslinger_joe -p 1403
gunslinger_joe@wildwildweb.fluxfingers.net's password:

           ,'-',
          :-----:
      (''' , - , ''')
      \   ' .  , `  /
       \  '   ^  ? /
        \ `   -  ,'
         `j_ _,'       Gunslinger Joe's
    ,- -`\ \  /f        Private Terminal
  ,-      \_\/_/'-
 ,                 `,
 ,          Joe      ,
      /\          \
|    /             \   ',
,   f  :           :`,  ,
<...\  ,           : ,- '
\,,,,\ ;           : j  '
 \    \            :/^^^^'
  \    \            ; ''':
    \   -,         -`.../
     '    - -,`,--`
      \_._'-- '---:

$ ls
$ whoami
$ ls -l
: -: command not found
```

Something weird have just happened... It seems that the shell filtered out all
the alphabetic characters. However, the "FLAG" showed up...

```bash
$ *
: ./FLAG: Permission denied
```

Apparently, the file FLAG does not have a attribute of execution so the shell
told us it cannot execute the file FLAG. Anyway, using asterisk could reveal
some useful information. Then try it under the root directory.

```bash
$ /*
: /bin: Is a directory
```

To conclude, with this kind of input (asterisk), the shell will want to execute
the very first file in the directory specified. So let's see what is the first
executable in the `/bin`.

```bash
/*/*
```

Oops! WTF! It seems that the file `/bin/bashbug` has been executed. And we
finally got an editor, which is `vim`.

```text
From: gunslinger_joe
To: ../../bin/bunzip2
Subject: [50 character or so descriptive subject here (for reference)]

Configuration Information [Automatically generated, do not change]:
Machine: x86_64
OS: linux-gnu
Compiler: gcc
Compilation CFLAGS:  -DPROGRAM='bash' -DCONF_HOSTTYPE='x86_64' -DCONF
OSTYPE='linux-gnu' -DCONF_MACHTYPE='x86_64-unknown-linux-gnu'
-DCONF_VENDOR='unknown' -DLOCALEDIR='//share/locale' -DPACKAGE='bash'
-DSHELL -DHAVE_CONFIG_H   -I.  -I. -I./include -I./lib   -g -O2
uname output: Linux terminal 3.13.0-37-generic #64-Ubuntu SMP Mon Sep 22
21:28:38 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
Machine Type: x86_64-unknown-linux-gnu

Bash Version: 4.3
Patch Level: 30
Release Status: release

Description:
        [Detailed description of the problem, suggestion, or complaint.]

Repeat-By:
        [Describe the sequence of events that causes the problem
        to occur.]

Fix:
        [Description of how to fix the problem.  If you don't know a
        fix for the problem, don't include this section.]
```

Gods be good, we all know that anyone can execute any commands in `vim` using
`:! <command>`. So I tried `:! cat FLAG`. But the system told me there was
no more resources to fork another process to do the work. Where there is a
will, there is a way. Using the tab page feature provided by `vim` could do
the work! Because `vim` will not spawn a new process to handle the new tab
page.

## Flag

```text
flag{joe_thought_youd_suck_at_bash}
```
