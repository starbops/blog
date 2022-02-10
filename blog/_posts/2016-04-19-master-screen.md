---
layout: post
title: 'Mastering Screen'
category: note
slug: mastering-screen
---
You probably familiar with manipulating screen operations in your screen
sessions. How about "outside" the screen session? Here are some tips about it.
If you're interested, please have a look.

## Manipulate Screen from Outer Space

Create screen session with a window running specified command:

```bash
screen -dmS testing -t shell bash
```

Turn on log:

```bash
screen -S testing -pshell -X logfile "/tmp/screen-pshell.log"
screen -S testing -pshell -X log on
```

Run command:

```bash
screen -S testing -pshell -X stuff 'ping 8.8.8.8\015'
```

Take a peek at screen window:

```bash
screen -S testing -pshell -X hardcopy $(tty)
```

Create new window in the screen session:

```bash
screen -S testing -X screen -t monitoring bash
```

Run command in previously created window:

```bash
screen -S testing -pmonitoring -X stuff 'htop\015'
```

Terminate foreground running process through keyboard interrupt:

```bash
screen -S testing -pshell -X stuff '\003'
```

Kill specific window of the screen:

```bash
screen -S testing -pshell -X kill
```

Quit entire screen Session:

```bash
screen -S testing -X quit
```

Okay, the aforementioned skills are useful enough. But why should I use them?
Under what circumstances should I create a new window inside specific screen
session? And I'll provide an example below.

## A More Complex Application

Suppose I want to run a command in foreground, say `ping`, and keep track of
its pid if it is running. Otherwise the failure message should be logged.
Though this scenario is a bit trivial, it help us get to understand how to
assemble the screen skills learnt above.

The service `ping` will success, and its pid is in `ping.pid`. The service
continues running on foreground:

```bash
screen -S testing -pshell -X stuff 'ping 8.8.8.8 & echo $! > ping.pid; fg || echo "ping failed to start" | tee "ping.failure"\015'
```

The service `ping` will fail, and the error message will be written in
`ping.failure`:

```bash
screen -S testing -pshell -X stuff 'ping 8.8.8. & echo $! > ping.pid; fg || echo "ping failed to start" | tee "ping.failure"\015'
```

## References

-  [StackExchange - Send command to detached screen and get the
   output](http://unix.stackexchange.com/questions/110055/send-command-to-detached-screen-and-get-the-output)
-  [StackExchange - How to open tabs windows in Gnu-screen & execute commands
   within each
   one](http://unix.stackexchange.com/questions/74785/how-to-open-tabs-windows-in-gnu-screen-execute-commands-within-each-one)
