---
layout: post
title: 'Poudriere - A FreeBSD Package Building Tool'
category: note
slug: poudriere-a-freebsd-package-building-tool
---
Poudriere is used by FreeBSD project to build the official `pkg` repositories.

## Prerequisites

```bash
sudo portsnap fetch
sudo portsnap extract
```

```bash
sudo portsnap fetch
sudo portsnap update
```

### ZFS

```bash
sudo zpool create -m /poudriere ztank /dev/vtbd1
```

## Installation

```bash
sudo pkg install poudriere
```

## Configuration

Poudriere's main config file is `/usr/local/etc/poudriere.conf`:

```text
ZPOOL=ztank
ZROOTFS=/poudriere
FREEBSD_HOST=https://freebsd.cs.nctu.edu.tw
RESOLV_CONF=/etc/resolv.conf
BASEFS=/poudriere
USE_PORTLINT=no
USE_TMPFS=yes
DISTFILES_CACHE=/usr/ports/distfiles
ALLOW_MAKE_JOBS=yes
```

## Basic Workflow

### Create Jail

```bash
sudo poudriere jail -c -j 112x64 -v 11.2-RELEASE
```

### Create Ports Tree

```bash
sudo poudriere ports -c -p default
```

### Configure Options

```bash
sudo poudriere options -p default -n security/sudo
```

### Build Packages

```bash
sudo poudriere bulk -j 112x64 -p default -z zpcc -f /usr/local/etc/poudriere.d/packages-zpcc
```

## Package Management Memo

```bash
$ pkg info --dependencies p5-Net-SMTP-SSL
p5-Net-SMTP-SSL-1.04:
        p5-IO-Socket-SSL-2.044
        perl5-5.24.1
```

```bash
$ pkg info --required-by perl5
perl5-5.24.1:
        p5-Socket-2.024
        p5-Mozilla-CA-20160104
        p5-GSSAPI-0.28_1
        p5-Digest-HMAC-1.03_1
        p5-Net-SMTP-SSL-1.04
        p5-Error-0.17024
        p5-Authen-SASL-2.16_1
        p5-Net-SSLeay-1.80
        p5-IO-Socket-IP-0.39
        p5-IO-Socket-SSL-2.044
        git-2.12.1
```

# References

-  [VladimirKrstulja/Guides/Poudriere - FreeBSD
   Wiki](https://wiki.freebsd.org/VladimirKrstulja/Guides/Poudriere)
-  [4.6. Building Packages with
   Poudriere](https://www.freebsd.org/doc/handbook/ports-poudriere.html)
-  [How To Build and Deploy Packages for Your FreeBSD Servers Using Buildbot and
   Poudriere |
   DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-build-and-deploy-packages-for-your-freebsd-servers-using-buildbot-and-poudriere)
