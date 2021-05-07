---
layout: post
title: 'Install DRBD on CentOS 6.9 (Active/Passive)'
category: memo
slug: install-drbd-on-centos-69-active-passive
---
This is an relatively simple guide about how to install DRBD (Distributed Replicated Block Device) on two CentOS 6.9 hosts in active/passive mode as block-level data failover.

## DRBD Introduction

The DRBD is a software-based, shared-nothing, replicated storage solution mirroring the content of block devices (hard disks, partitions, logical volumes etc.) between hosts.

DRBD mirrors data

- **in real time**. Replication occurs continuously while applications modify the data on the device.
- **transparently**. Applications need not be aware that the data is stored on multiple hosts.
- **synchronously** or **asynchronously**. With synchronous mirroring, applications are notified of write completions after thewrites have been carried out on all hosts. With asynchronous mirroring, applications are notified of write completions when the writes have completed locally, which usually is before they have propagated to the other hosts.

### Kernel Module

DRBD's core functionality is implemented by way of a Linux kernel module. Specifically, DRBD consititutes a driver for a virtual block device, so DRBD is situated right near the bottom of a system's I/O stack. Because of this, DRBD is extremely flexible and versatile, which makes it a replication solution suitable for adding high availability to just about any application.

DRBD is, by definition and as mandated by the Linux kernel architecture, agnostic of the layers above it. Thus, it is impossible for DRBD to miraculously add features to upper layers that these do not possess. For example, DRBD cannot auto-detect file system corruption or add active-active clustering capability to file systems like ext3 or XFS.

![DRBD in Kernel](https://docs.linbit.com/ug/users-guide-8.4/drbd-in-kernel.png)

### User Space Administration tools

DRBD comes with a set of administration tools which communicate with the kernel module in order to configure and administer DRBD resources.

`drbdadm`. The high-level administration tool of the DRBD program suite. Obtains all DRBD configuration parameters from the configuration file `/etc/drbd.conf` and acts as a front-end for `drbdsetup` and `drbdmeta`. `drbdadm` has a *dry-run* mode, invoked with the `-d` option, that shows which `drbdsetup` and `drbdmeta` calls `drbdadm` would issue without actually calling those commands.

`drbdsetup`. Configures the DRBD module loaded into the kernel. All parameters to `drbdsetup` must be passed on the command line. The separation between `drbdadm` and `drbdsetup` allows for maximum flexibility. Most users will rarely need to use `drbdsetup` directly, if at all.

`drbdmeta`. Allows to create, dump, restore, and modify DRBD meta data structures. Like `drbdsetup`, most users will only rarely need to use `drbdmeta` directly.

## Environment Information

In this article, there are two hosts, both are installed with CentOS 6.9:

- `carlos`
    - IP address: 10.0.1.133
- `carol`
    - IP address: 10.0.1.233

We'll make `carlos` as DRBD primary node and `carol` as secondary node. Most of the actions done below should be executed on both hosts, while some are not. Please be sure what you are doing.

## Installation

First we need to upgrade the system and install some build-time dependencies:

```bash
[root@carlos ~]# yum -y update
[root@carlos ~]# yum -y install gcc make automake autoconf libxslt libxslt-devel flex rpm-build kernel-devel
```

Construct the RPM build directory tree. Download DRBD community source code from [here](https://www.linbit.com/en/drbd-community/drbd-download/). We'll
need to build the code and then package them into RPMs.

```bash
[root@carlos ~]# mkdir -p /root/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
[root@carlos ~]# wget http://www.linbit.com/downloads/drbd/8.4/drbd-8.4.7-1.tar.gz http://www.linbit.com/downloads/drbd/utils/drbd-utils-8.9.9.tar.gz
```

Extract source code from tarballs:

```bash
[root@carlos ~]# tar -zxvf drbd-8.4.7-1.tar.gz
[root@carlos ~]# tar -zxvf drbd-utils-8.9.9.tar.gz
```

```bash
[root@carlos ~]# cd drbd-8.4.7-1
[root@carlos drbd-8.4.7-1]# make km-rpm
```

```bash
[root@carlos drbd-8.4.7-1]# cd ../drbd-utils-8.9.9
[root@carlos drbd-utils-8.9.9]# ./configure
[root@carlos drbd-utils-8.9.9]# make rpm
```

```bash
[root@carlos drbd-utils-8.9.9]# cd /root/rpmbuild/RPMS/x86_64
[root@carlos x86_64]# rpm -Uvh drbd-xen-8.9.9-1.el6.x86_64.rpm drbd-udev-8.9.9-1.el6.x86_64.rpm drbd-pacemaker-8.9.9-1.el6.x86_64.rpm drbd-bash-completion-8.9.9-1.el6.x86_64.rpm drbd-utils-8.9.9-1.el6.x86_64.rpm drbd-km-*.rpm drbd-8.9.9-1.el6.x86_64.rpm
```

## Configuration

DRBD requires the same name as its hostname, so please verify that they're the same:

```bash
[root@carlos ~]# uname -n
carlos
```

Optional: edit `/etc/hosts` to set hostname alias for convenience:

```
...
10.0.1.133 carlos
10.0.1.233 carol
```

We'll create a new disk partition to act as DRBD disk. Both hosts have a new disk `/dev/sdb`. Let's create a partition `dev/sdb1` and use it as DRBD disk.

```bash
[root@carlos ~]# fdisk -l

Disk /dev/sda: 17.2 GB, 17179869184 bytes
255 heads, 63 sectors/track, 2088 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x0006ac64

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *           1          64      512000   83  Linux
Partition 1 does not end on cylinder boundary.
/dev/sda2              64        2089    16264192   8e  Linux LVM

Disk /dev/sdb: 17.2 GB, 17179869184 bytes
255 heads, 63 sectors/track, 2088 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00077967

   Device Boot      Start         End      Blocks   Id  System

Disk /dev/mapper/vg_carlos-lv_root: 14.9 GB, 14935916544 bytes
255 heads, 63 sectors/track, 1815 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000

Disk /dev/mapper/vg_carlos-lv_swap: 1715 MB, 1715470336 bytes
255 heads, 63 sectors/track, 208 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000

[root@carlos ~]# fdisk /dev/sdb

WARNING: DOS-compatible mode is deprecated. It's strongly recommended to
         switch off the mode (command 'c') and change display units to
         sectors (command 'u').

Command (m for help): n
Command action
   e   extended
   p   primary partition (1-4)
p
Partition number (1-4): 1
First cylinder (1-2088, default 1):
Using default value 1
Last cylinder, +cylinders or +size{K,M,G} (1-2088, default 2088):
Using default value 2088

Command (m for help): p

Disk /dev/sdb: 17.2 GB, 17179869184 bytes
255 heads, 63 sectors/track, 2088 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00077967

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1               1        2088    16771828+  83  Linux

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

Repeat the steps above on the other host.

After creating DRBD disks on both hosts, it's time to create resource configuration file of DRBD. Edit `/etc/drbd.d/s1.res`:

```
resource s1 {
  on carlos {
    device /dev/drbd0;
    disk /dev/sdb1;
    address 10.0.1.133:7799;
    meta-disk internal;
  }
  on carol {
    device /dev/drbd0;
    disk /dev/sdb1;
    address 10.0.1.233:7799;
    meta-disk internal;
  }
}
```

In DRBD, *resource* is the collective term that refers to all aspects of a particular replicated data set. These include:

**Resource name**. This can be any arbitrary, US-ASCII name not containing whitespace by which the resource is referred to.

**Volumes**. Any resource is a replication group consisting of one of more *volumes* that share a common replication stream. DRBD ensures write fidelity across all volumes in the resource. Volumes are numbered starting with `0`, and there may be up to 65535 volumes in one resource. A volume contains the replicated data set, and a set of metadata for DRBD internal use.

At the `drbdadm` level, a volume within a resource can be addressed by the resource name and volume number as `<resource>/<volume>`.

**DRBD device**. This is a virtual block device managed by DRBD. It has a device major number of 147, and its minor numbers are numbered from 0 on wards, as is customary. Each DRBD device corresponds to a volume in a resource. The associated block device is usually named `/dev/drbdX`, where `X` is the device minor number. DRBD also allows for user-defined block device names which must, however, start with `drbd_`.

In this file we define our resource as `s1`, using `/dev/sdb1` on both hosts as DRBD disk `/dev/drbd0`. Also, the hosts' IP addresses are shown, too. This DRBD configuration file must be identical between two nodes. So we'll copy it to the other host.

```bash
[root@carlos ~]# scp /etc/drbd.d/s1.res root@carol:/etc/drbd.d/
```

## Up and Running

Load DRBD kernel module and check if it is actually loaded:

```bash
[root@carlos ~]# modprobe drbd
[root@carlos ~]# lsmod | grep drbd
drbd                  372567  4
libcrc32c               1246  1 drbd
```

```bash
[root@carlos ~]# drbdadm create-md s1

  --==  Thank you for participating in the global usage survey  ==--
The server's response is:

you are the 21721th user to install this version
initializing activity log
NOT initializing bitmap
Writing meta data...
New drbd meta data block successfully created.
success
```

```bash
[root@carlos ~]# service drbd status
drbd driver loaded OK; device status:
version: 8.4.7-1 (api:1/proto:86-101)
GIT-hash: 3a6a769340ef93b1ba2792c6461250790795db49 build by root@carlos, 2018-03-14 17:33:07
m:res  cs  ro  ds  p  mounted  fstype
```

```bash
[root@carlos ~]# service drbd start
Starting DRBD resources: [
     create res: s1
   prepare disk: s1
    adjust disk: s1
     adjust net: s1
]
..........
***************************************************************
 DRBD's startup script waits for the peer node(s) to appear.
 - If this node was already a degraded cluster before the
   reboot, the timeout is 0 seconds. [degr-wfc-timeout]
 - If the peer was available before the reboot, the timeout
   is 0 seconds. [wfc-timeout]
   (These values are for resource 's1'; 0 sec -> wait forever)
 To abort waiting enter 'yes' [ 163]:
.
```

You'll see that DRBD is actually not ready, it's waiting for other DRBD nodes to come up. At the same time please login to the other host using another SSH session, then start the DRBD service. And both DRBD service will started successfully.

The following command will initialize the primary server. Please notice that this should be executed only once on primary server of your choice (e.g. on `carlos`).

```bash
[root@carlos ~]# drbdadm -- --overwrite-data-of-peer primary s1
```

Now check DRBD status on the other host:

```bash
[root@carol ~]# service drbd status
drbd driver loaded OK; device status:
version: 8.4.7-1 (api:1/proto:86-101)
GIT-hash: 3a6a769340ef93b1ba2792c6461250790795db49 build by root@carol, 2018-03-14 17:34:22
m:res  cs          ro                 ds                     p  mounted  fstype
0:s1   SyncTarget  Secondary/Primary  Inconsistent/UpToDate  C
...    sync'ed:    1.0%               (16228/16376)M
```

After a while the DRBD status will tell you that it's fully synced between primary and secondary nodes. We're done!

```bash
[root@carlos ~]# service drbd status
drbd driver loaded OK; device status:
version: 8.4.7-1 (api:1/proto:86-101)
GIT-hash: 3a6a769340ef93b1ba2792c6461250790795db49 build by root@carlos, 2018-03-14 17:33:07
m:res  cs         ro                 ds                 p  mounted  fstype
0:s1   Connected  Primary/Secondary  UpToDate/UpToDate  C
```

## Verification

```bash
[root@carlos ~]# mkfs.ext4 /dev/drbd0
[root@carlos ~]# mount /dev/drbd0 /mnt
[root@carlos ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/vg_carlos-lv_root
                       14G  2.2G   11G  17% /
tmpfs                 939M     0  939M   0% /dev/shm
/dev/sda1             477M   77M  376M  17% /boot
/dev/drbd0             16G   44M   15G   1% /mnt
[root@carlos ~]# dd if=/dev/zero of=/mnt/testfile bs=1M count=30
[root@carlos ~]# ls -l /mnt
total 30736
drwx------. 2 root root    16384 Mar 14 19:56 lost+found
-rw-r--r--. 1 root root 31457280 Mar 14 19:57 testfile
```

```bash
[root@carlos ~]# umount /mnt
[root@carlos ~]# drbdadm secondary s1
[root@carlos ~]# service drbd status
drbd driver loaded OK; device status:
version: 8.4.7-1 (api:1/proto:86-101)
GIT-hash: 3a6a769340ef93b1ba2792c6461250790795db49 build by root@carlos, 2018-03-14 17:33:07
m:res  cs         ro                   ds                 p  mounted  fstype
0:s1   Connected  Secondary/Secondary  UpToDate/UpToDate  C
```

Now both DRBD nodes are in secondary mode.

And we switch to the other host and make it as primary node, then check its status. You can see that the host is being primary now. It means you can mount the partition and the same data will show up in the end.

```bash
[root@carol ~]# drbdadm primary s1
[root@carol ~]# service drbd status
version: 8.4.7-1 (api:1/proto:86-101)
GIT-hash: 3a6a769340ef93b1ba2792c6461250790795db49 build by root@carol, 2018-03-14 17:34:22
m:res  cs         ro                 ds                 p  mounted  fstype
0:s1   Connected  Primary/Secondary  UpToDate/UpToDate  C
[root@carol ~]# mount /dev/drbd0 /mnt
[root@carol ~]# ls -l /mnt
total 30736
drwx------. 2 root root    16384 Mar 14 19:56 lost+found
-rw-r--r--. 1 root root 31457280 Mar 14 19:57 testfile
```

## References

- [Chapter 1. DRBD fundamentals - Docs LINBIT](https://docs.linbit.com/doc/users-guide-84/ch-fundamentals/)
- [How to install and setup DRBD on CentOS](https://www.howtoforge.com/tutorial/how-to-install-and-setup-drbd-on-centos-6/)
