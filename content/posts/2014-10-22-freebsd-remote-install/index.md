---
title: FreeBSD Remote Installation
category: memo
slug: freebsd-remote-install
date: 2014-10-22
---
Sometimes we don't want to do the installation in front of the console

## Before Started

### Writable Filesystem

```bash
mkdir /tmp/etc
mount_unionfs /tmp/etc /etc
```

### Connectivity

```bash
ifconfig em0 140.113.102.184 netmask 255.255.255.224
route add default 140.113.102.190
echo 'nameserver 8.8.8.8' > /tmp/etc/resolv.conf
```

### SSHD on Duty

```bash
passwd
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
service sshd onestart
```

## Remote Installation

```bash
gpart destroy -F /dev/da0
gpart create -s GPT /dev/da0
gpart add -s 128 -t freebsd-boot -l gptboot /dev/da0
gpart add -s 1G -t freebsd-swap -l gptswap /dev/da0
gpart add -t freebsd-ufs -l gptroot /dev/da0
gpart bootcode -b /boot/pmbr -p /boot/gptboot -i 1 /dev/da0
swapon /dev/gpt/gptswap
newfs -U /dev/gpt/gptroot
mount /dev/gpt/gptroot /mnt

tar Jxf /usr/freebsd-dist/base.txz   -C /mnt
tar Jxf /usr/freebsd-dist/kernel.txz -C /mnt
tar Jxf /usr/freebsd-dist/doc.txz    -C /mnt
tar Jxf /usr/freebsd-dist/src.txz    -C /mnt
tar Jxf /usr/freebsd-dist/lib32.txz  -C /mnt

chroot /mnt
```

```bash
passwd
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
mkdir -p /usr/compat/linux/proc
ln -s /usr/compat /compat
ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime
```

Edit `/etc/rc.conf`

```text
hostname="chcbsd.zespre.com"
ifconfig_em0="inet 140.113.102.184 netmask 255.255.255.224"
defaultrouter="140.113.102.190"

dumpdev="NO"
background_fsck="NO"
fsck_y_enable="YES"

sshd_enable="YES"
sendmail_enable="NO"
ntpd_enable="YES"
ntpd_sync_on_start="YES"
#pf_enable="YES"
#pflog_enable="YES"
```

Edit `/etc/fstab`

```text
# Device            Mountpoint          FStype      Options Dump    Pass#
/dev/gpt/gptswap    none                swap        sw      0       0
/dev/gpt/gptroot    /                   ufs         rw      1       1
linproc             /compat/linux/proc  linprocfs   rw,late 0       0
fdesc               /dev/fd             fdescfs     rw      0       0
proc                /proc               procfs      rw      0       0
```

Remove install media then reboot.

## After Installation

You need to console login using root if you did not create normal user before
you reboot the machine

```bash
pw useradd starbops -G wheel -m -s /bin/sh
```

Download ports tree if you want to install software through ports

```bash
portsnap fetch extract
```

## Conclusion

From now on you have a basic FreeBSD server. You can do anything you want. But
be careful, this is a very basic installation guide. My point is to do the
installation remotely, so many settings are very rough.
