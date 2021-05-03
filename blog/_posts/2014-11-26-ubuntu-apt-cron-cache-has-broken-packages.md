---
layout: post
title: 'Ubuntu Apt Cron Cache Has Broken Packages'
category: memo
slug: ubuntu-apt-cron-cache-has-broken-packages
---
One day I received an root mail from my machine, talking about some packages are broken in the cache. The investigation begins...

## Problem Encountered

I received a root mail from my machine this morning, contents are shown below:

```
Subject: Cron <root@win> test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )

/etc/cron.daily/apt:
Cache has broken packages, exiting
```

## Search for Solutions

First of all, collect all information which could be useful for later searching.
Unfortunately, the only information is that root mail. So I fed Google with the
error message, I found one post discussing about this problem. Someone said that
was because the root file system was low on free inodes, but not free space.
We can check this by `df -i`

```bash
$ df -i
Filesystem             Inodes  IUsed     IFree IUse% Mounted on
/dev/sda1              327680 324403      3277   99% /
udev                   253837    445    253392    1% /dev
tmpfs                  256454    351    256103    1% /run
none                   256454      2    256452    1% /run/lock
none                   256454      1    256453    1% /run/shm
/dev/sdd1              327680   4013    323667    2% /lib/modules
/dev/md0              1310720 240845   1069875   19% /home
```

Ah-ha! This might be the problem! So our goal is turning to "how to reduce the
inodes which are being used?". The guy in the forum also mentioned that removing
old linux-kernel-\* and linux-headers-\* will fix the problem. But how to remove
them? Where are they?

Another article told us how to purge old and useless linux images and header
packages by using `dpkg`

```bash
# dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
```

After seeing this, I gave it a try but failed with the dependency warning. The
warning said that I must install "linux-headers-3.2.0-72" because
"linux-headers-3.2.0-72-generic" needs it. So I install the dependency according
to the instruction it provided:

```bash
# apt-get -f install
```

Unfortunately, it failed again because there was no free disk space any more.
I faced a dead lock between installation and uninstallation! What a joke...

## My Solution, Ugly

Also, the running kernel version is not the newest, which means the system
administrator has not reboot the machine since kernel upgrade.

```bash
$ uname -r
3.2.0-67-generic
```

I found many `linux-headers-3.2.0-xx` and `linux-headers-3.2.0-xx-generic`
are under `/usr/src` directory. So chances are that I may move those
directories to another place which is not under root directory. And I did it.
Now we can install the dependencies by `sudo apt-get -f install linux-headers-3.2.0-72`

After the dependencies were installed, we can remove all the previous kernel
images, headers and modules, leaving only the current one intact. Using the one
liner specified in last section will do the trick. (But it is important that the
machine should reboot before purging the old kernel images. If you did not
reboot, next time rebooting the machine will fail because it cannot find the
kernel image.) After all, our precious disk space is returned!

To prove that our work does solve the original problem, we simply run the cron
job manually:

```bash
$ cd /
# run-parts --report /etc/corn.daily
```

Waiting about 20 minutes, this time no more errors are shown. Hooray!

## References

- [/etc/cron.daily/apt: Cache has broken packages, exiting][1]
- [How to Remove Old Linux Kernel Headers][2]

[1]: https://bugs.launchpad.net/ubuntu/+source/apt/+bug/482200
[2]: https://howto8165.wordpress.com/2014/08/13/remove-old-linux-kernels/
