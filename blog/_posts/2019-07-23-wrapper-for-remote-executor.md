---
layout: post
title: 'Wrapper for Remote Executor'
category: note
slug: wrapper-for-remote-executor
---
Currently BAMPI uses remote executor to do various types of tasks. Apart from Ironic's agent pattern, remote executor is based on SSH. For high availability design, we need to consider a lot of situations, one is "while during task execution, BAMPI-1 fails". In this situation, remote executor is dead, but the
task being run still remains on the target bare-metal. So how does BAMPI-2 take over this kind of situation?

By doing some experiments, we found that although the SSH connection is broken, the processes started by that SSH session still goes on. The real question is, how to prevent BAMPI-2 running new tasks on the same bare-metal which already has a running task? To differentiate whether a bare-metal has a previous executed task or not, try to use `ps`. For example, when Bob logins to a server and executes `sleep 100 &`, then he logouts, that "sleep" process is still running in the background. However, its parent process is no longer being Bob's shell. These kind of processes are called "orphan process": an orphan process is a computer process whose parent process has finished or terminated, though it remains running itself. All the orphan processes' parent process is `init` which has PID 1.

So the answer is clear: find the orphan processes and wipe them out! But there might be some other processes' parent process ID is 1, e.g. the processes spawned by `init` or other orphan processes not started by BAMPI at the beginning. And there are various types of tasks that BAMPI can run. So one
suggestion is that, in addition to BAMPI's remote executor, write another "wrapper" that runs on bare-metal. Therefore we can combine these two condition: parent process ID is 1 and process name equals to the name of wrapper. Ta-da!
