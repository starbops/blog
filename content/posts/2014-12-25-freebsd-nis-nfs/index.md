---
title: Setting NIS & NFS on FreeBSD
category: memo
slug: freebsd-nis-nfs
date: 2014-12-25
---
I want to build a Micro Computer Center (MCC)

## Requirement & Architecture

There will be 3 machines in the MCC environment.

-  sahome (NIS master server, NFS server)
-  saduty (NIS slave server, NFS client)
-  sabsd (NIS client, NFS client)

The architecture is shown below:

```text
        sa-core
+-----------------------+
|                       |
|  +========+           |
|  |        | NIS master|
|  | sahome | NFS server|
|  |        |           |
|  +========+           |
|      ^                |
|      | SSH            |
|      v                |
|  +========+           |           +=======+
|  |        | NIS slave |       +-> |       | NIS client
|  | saduty | NFS client|       |   | sabsd | NFS client
|  |        | <-----------------+   |       | <-------------
|  +========+           | SSH       +=======+   SSH
|                       |
+-----------------------+
```

A bunch of requirements should be satisfied:

-  Full Network Information System (NIS) environment
   -  Groups
      -  samaster (god)
         -  sysadm (can access /net/data/sata)
         -  nctucs (normal user)
   -  Netgroups
      -  sa-adm (admin users who can login to sa-core)
      -  sa-core (sahome and saduty)
      -  sa-bsd (all servers in MCC)
-  Full Network File System (NFS) environment
   -  Users are allowed to login servers with unfied accounts through NIS
   -  Users' home directory `/net/home` are exported from sahome through NFS
   -  Share data `/net/data` that are needed by other servers through NFS
   -  Share admin's data `/net/admin` only to saduty
   -  Ports directory also shared through NFS
-  Using Auto Mount Daemon (AMD) to implement on-demand file system
   mounting/unmounting
-  Share `sudoers` configuration file at `/net/data/sudoers`
-  Using `rup` to monitor servers' states
-  Centralized log server at sahome

## Network Information System

Both NIS and NFS are based on Remote Procedure Call (RPC) services. So RPC must
be enabled first in order to run as an NIS server or an NIS client. Also, NIS
server and client must share an NIS domain name. This domain name is nothing to
do with DNS. In `/etc/rc.conf`:

```text
## NIS & NFS
rpcbind_enable="YES"
nisdomainname="+sa.nis"
```

To achieve NIS account login and access control, some user authentication
configuration files should be edited in all NIS domain machines (remember the
NIS server is also an NIS client). Otherwise users could not login to these
machines. One is `/etc/master.passwd`. Use `vipw` to modify this file, it
will modify the corresponding `/etc/passwd` automatically. In this file,
netgroup of NIS could be used to achieve access control. Append the following
two lines:

```text
+@sa-adm:::::::::
+:::::::::/usr/sbin/nologin
```

Also the `/etc/group`:

```text
+:*:0:
```

### NIS Master Server

Now is time for NIS master server! The NIS is so called YP (Yello Page). Also
the name of the NIS daemon is `ypserv`. All NIS server should run this daemon
to be a true NIS server regardless of master or slave. And `yppasswdd` is
another daemon which allows NIS clients to change their NIS passwords. But it
should only run on NIS **master** server. To run these daemons on the startup,
edit `/etc/rc.conf`:

```text
## NIS Master Server
nis_server_enable="YES"
nis_yppasswdd_enable="YES"
nis_yppasswdd_flags="-v -u -d +sa.nis"
```

Before initializing the maps, start the NIS server (*disputed*).

```bash
# service ypserv start
```

Place the files which should be shared in `/var/yp`. Some of them are copied
from `/etc`, some are generated manually.

```bash
# cp /etc/master.passwd /var/yp
# cp /etc/group /var/yp/
# touch /var/yp/netgroup
# touch /var/yp/hosts
# touch /var/yp/amd.map
```

System accounts and groups should not be shared by NIS to other hosts inside
the NIS domain. So the following two points should be done with
`master.passwd` and `group`:

-  Remove system accounts and groups in `/var/yp/master.passwd` and
   `/var/yp/master.passwd`
-  Remove normal users and groups in `/etc/master.passwd` and `/etc/group`

Comment out the line in `/var/yp/Makefile` because there is a NIS slave
server need to be pushed every time the NIS map is changed.

```text
NOPUSH = "True"
```

Now it is time to generate the maps. Because this is a master server, a option
of `-m` should be added into the command:

```bash
# cd /var/yp
# ypinit -m +sa.nis
Server Type: MASTER Domain: +sa.nis

Creating an YP server will require that you answer a few questions.
Questions will all be asked at the beginning of the procedure.

Do you want this procedure to quit on non-fatal errors? [y/n: n]  n

Ok, please remember to go back and redo manually whatever fails.
If you don't, something might not work.

At this point, we have to construct a list of this domains YP servers.
zphome.zespre.com is already known as master server.
Please continue to add any slave servers, one per line. When you are
done with the list, type a <control D>.
        master server   :  sahome.zespre.com
        next host to add:  saduty.zespre.com
        next host to add:  ^D
The current list of NIS servers looks like this:

sahome.zespre.com
saduty.zespre.com

Is this correct?  [y/n: y]  y

... map generation output suppressed ...

NIS Map update completed.

sahome.zespre.com has been setup as an YP master server without any errors.
```

And now the NFS master server is up!

### NIS Slave Server

The configuration of NIS slave server is much simpler than the master. One
concept to remember is that "To be a slave, one must be a client first.". The
NIS server is also an NIS client which binds to themselves. But at the very
begining, there are no maps for the slave to host. Where is the NIS maps? The
answer is simple, "pull from master server". So be a NIS client first, get the
maps, then be a slave, host the maps. That is the strategy. In `/etc/rc.conf`
the order of the `nis_client_flags` varies depending on whom to bind to. In
our case, saduty binds to sahome when it is a client. After the maps are
retrieved, it binds to itself. The last one is the highest priority:

```text
## NIS Slave Server
nis_server_enable="YES"

## NIS Client
nis_client_enable="YES"
nis_client_flags="-s -m -S +sa.nis,sahome,saduty"
```

Use `-s` instead of `-m` in `ypinit` command. Also specify master server
and NIS domain in the command.

```bash
# ypinit -s sahome +sa.nis

Server Type: SLAVE Domain: +sa.nis Master: zphome

Creating an YP server will require that you answer a few questions.
Questions will all be asked at the beginning of the procedure.

Do you want this procedure to quit on non-fatal errors? [y/n: n]  n

Ok, please remember to go back and redo manually whatever fails.
If not, something might not work.
There will be no further questions. The remainder of the procedure
should take a few minutes, to copy the databases from zphome.
Transferring master.passwd.byuid...
ypxfr: Exiting: Map successfully transferred

... map generation output suppressed ...

zpduty has been setup as an YP slave server without any errors.
Remember to update map ypservers on zphome.
```

This will generate a directory called `+sa.nis` under `/var/yp` which
contains the copy of the NIS maps in master server. Now the slave is ready to
serve.

### NIS Client

Now is time for the client. We make the client bind to the slave server,
saduty, by editing `/etc/rc.conf`.

```text
## NIS Client
nis_client_enable="YES"
nis_client_flags="-s -m -S +sa.nis,sahome,saduty"
```

Make sure name service switch configuration file `/etc/nsswitch.conf` is set
properly. Some system configuration files need to be search through NIS, e.g.
hosts.

```text
#
# nsswitch.conf(5) - name service switch configuration file
# $FreeBSD: releng/10.1/etc/nsswitch.conf 224765 2011-08-10 20:52:02Z dougb $
#
group: compat
group_compat: nis
hosts: files dns nis
networks: files
passwd: compat
passwd_compat: nis
shells: files
services: compat
services_compat: nis
protocols: files
rpc: files
```

### If You Want to Add A New User

First of all, the administrator must be in NIS master server, e.g. sahome. Here
I use `pw` to do the work, while it is not that perfect.

```bash
# pw useradd newuser -V /var/yp -b /net/home -h 0 -Y
```

If the option `-h 0` is used, the system will ask you for new user's
password. It is an interface of `pw`. Other program could communicate with
it.

Other options could be added if you want. But actually, after testing several
rounds, I found that it is impossible to create the home directory for the new
user if `-V etcdir` option is specified. One possible reason is that it might
be a security concern. Writing a wrapper script that created the account and
then built the home directory is a solution that come to my mind... However,
there is a workaround:

```bash
# pw usermod newuser -m
```

Create the home directory of the new user by `pw usermod`.

## Network File System

Some applications require file locking to operate correctly. To enable locking,
add the following two lines in `/etc/rc.conf`:

```text
## Locking
rpc_lockd_enable="YES"
rpc_statd_enable="YES"
```

### NFS Server

As an NFS server, one must export something to the others. This is done by
`mountd`. And `nfsd` is responsible for handling requests from NFS clients.

`/etc/rc.conf`

```text
## NFS Server
nfs_server_enable="YES"
nfs_server_flags="-u -t -n 10"
mountd_flags="-r"
nfs_reserved_port_only="YES"
```

We share four directories through NFS Each has its own attributes and
permissions:

-  `/net/data`
-  `/net/home`
-  `/net/admin`
-  `/usr/ports`

Settings should be placed in `/etc/exports`:

```text
#################################
#       Read-only exports
#################################
#
/net/data -ro -maproot=nobody sa-bsd
/usr/ports -ro -maproot=root sa-bsd
#
##########################################################
#       Read-write exports
#       XXX: All writable export *MUST* be specify host
##########################################################
#
/net/home -maproot=nobody sa-bsd
/net/admin -maproot=root sa-core
```

Once the exports file is modified, the `mountd` should be reloaded. The
`mountd` utility can be made to reload the exports file by:

```bash
# service mountd onereload
```

Prepending "one" on "reload" is because of that we did not specify
`mountd_enable="YES"` in `/etc/rc.conf`.

### NullFS

NFS has one minor restriction, but actually it is important in our situation
though. The manpage of NFS says that it could not share one file system twice
or even more. Since my sharing directory is `/net`, and I only mount one file
system on it, I cannot meet the requirement (share `/net/data`,
`/net/home/`, `/net/admin`, etc.). There are two solutions come to my mind:

1. Each sharing directory will have a file system (naive)
1. Using nullfs

If you just restart the NFS server, some horrible things will happen.

### NFS Client

Enabling NFS client at boot time, `/etc/rc.conf`:

```text
## NFS Client
nfs_client_enable="YES"
nfs_client_flags="-n 10"
```

## Auto Mount Daemon

Edit `/etc/rc.conf` and set some flags for amd.

```text
## AMD
amd_enable="YES"
amd_flags="-a /amd -c 1800 -y +sa.nis -l syslog -x all /net amd.map"
```

-  `-a /amd`: Alternative location for the real mount point, default is
   `/.amd_mnt`
-  `-c 1800`: A duration in seconds
-  `-y +sa.nis`: Specified an alternative NIS domain for fetching the
   `amd.map` file
-  `-l syslog`: Mount and unmount events will be recorded and sent to the log
   daemon by syslog
-  `-x all`: Runtime loggin options

The monitored directory is `/net`, symbolic links will be constructed here to
the real mount point under `/amd`.

`/var/yp/amd.map`

The first line begins with `/defaults`, which sets default parameters for all
entries below. The second line and others begin with the "keys". One can use
wildcard "\*" for key auto translation. Each entry specifies remote host, remote
file system, and some options. A bunch of parameters could be used. When trying
to access the "key" directory under the monitored directory, say `/net`, auto
mount daemon will mount the desired file system to the real mount point which
specified by `-a` option in amd flags.

```text
/defaults type:=nfsl;fs:=${autodir}/${key};opts:=grpid,intr,lockd,nodev,nosuid,quota,resvport,retrans=5,hard,timeo=10,rw,noac,acregmin=0,acregmax=0,acdirmin=0,acdirmax=0
home            -rfs:=/net/home;rhost:=sahome host==${rhost};fs:=${rfs} host!=${rhost}
data            -rfs:=/net/data;rhost:=sahome;addopts:=ro,noexec host==${rhost};fs:=${rfs} host!=${rhost}
admin           -rfs:=/net/admin;rhost:=sahome;addopts:=ro host==${rhost};fs:=${rfs} host!=${rhost}
ports           -rfs:=/usr/ports;rhost:=sahome;addopts:=ro,noexec host==${rhost};fs:=${rfs} host!=${rhost}
```

One important thing to do is that because `/usr/ports` are shared by sahome
with "read-only" permission, other machine that mount this share will not able
to compile ports right under the directory. To solve this, `/etc/make.conf`
should be modified:

```text
DISTDIR=        /tmp/distfiles
WRKDIRPREFIX=   /tmp/WRKDIR
```

## Sudo

We will create a shared `sudoers` file right in `/net/data`. Simple
permissions are defined in here:

-  Users of group samaster can issue any commands at any hosts as any users
-  Users of group sysadm can issue a specific set of commands at any hosts as
   any users
-  Users of group nctucs are not sudoers

```text
##
## Cmnd alias specification
##
Cmnd_Alias SHELLS=/bin/sh,/bin/tcsh,/bin/csh,/usr/local/bin/tcsh,\
                  /usr/local/bin/ksh,/usr/local/bin/bash,\
                  /usr/bin/sh,/usr/bin/tcsh,/usr/bin/csh,/usr/bin/bash,/bin/zsh,\
                  /usr/local/bin/zsh
Cmnd_Alias SYSADM=/bin/ls,/bin/cat,/usr/bin/top,/usr/bin/renice,/bin/kill,\
                  /sbin/reboot,/sbin/shutdown,\
                  sudoedit

##
## User privilege specification
##
%samaster ALL=(ALL) ALL,!SHELLS
%sysadm ALL=SYSADM,!SHELLS
```

In original `/usr/local/etc/sudoers` file, append this line to include other
sudoers configuration files:

```text
#include /net/data/sudoers
```

## RUP

Uncomment this line in `/etc/inetd.conf` to enable `rpc.rstatd` through
`inetd`.

```text
rstatd/1-3      dgram rpc/udp wait root /usr/libexec/rpc.rstatd  rpc.rstatd
```

The `rpc.rstatd` utility is a server which returns performance statistics
obtained from the kernel.

## Log Server

There are three machines in the MCC. Lots of logs will be generated. To
centralize the management of machines through logs, one should centralize the
logs storage, too. In the MCC, all the logs that generated by specific machines
are transfer to the loghost

Logs have priorities (levels). The following lines are coming from the manpage
of syslog(3):

1. LOG_EMERG: A panic condition. This is normally broadcast to all users.
1. LOG_ALERT: A condition that should be corrected immediately, such as a
   corrupted system database.
1. LOG_CRIT: Critical conditions, e.g., hard device error.
1. LOG_ERR: Errors.
1. LOG_WARNING: Warning messages.
1. LOG_NOTICE: Conditions that are not error conditions, but should possibly be
   handled specially.
1. LOG_INFO: Informational messages.
1. LOG_DEBUG: Messages that contain information normally of use only when
   debugging a program.

`/etc/rc.conf`

```text
syslogd_flags="-C -a saduty -a sabsd"
```

`/etc/syslog.conf`

```text
*.*                                             @loghost
```

## References

-  [Network Information System (NIS)](https://www.freebsd.org/doc/handbook/network-nis.html)
-  [adding NIS users and create homedir](http://lists.freebsd.org/pipermail/freebsd-questions/2003-August/016200.html)
-  [Using pw adduser to set password in a script](http://lists.freebsd.org/pipermail/freebsd-questions/2003-July/011018.html)
-  [Network File System (NFS)](https://www.freebsd.org/doc/handbook/network-nfs.html)
-  [架設 NIS 驗證伺服器](http://www.weithenn.org/2009/07/nis.html)
-  [Re: NIS-master/slave w/ 2.1.7+2.2.2](http://markmail.org/message/qlphkdn6pvthb6ao#query:+page:1+mid:qlphkdn6pvthb6ao+state:results)
-  [misc/145910: Problem with nullfs in fstab on boot](http://lists.freebsd.org/pipermail/freebsd-bugs/2010-April/039579.html)
-  [Configuring NFS in FreeBSD](http://troysunix.blogspot.tw/2011/03/configuring-nfs-in-freebsd.html)
-  [Configuring AutoFS in FreeBSD](http://troysunix.blogspot.tw/2012/10/configuring-autofs-in-freebsd.html)
-  [Take Control of your Linux \| sudoers file: How to with Examples](http://www.garron.me/en/linux/visudo-command-sudoers-file-sudo-default-editor.html)
-  [Syslog - FreeBSDwiki](http://www.freebsdwiki.net/index.php/Syslog)
