---
title: Construct Your FreeBSD Ports Testing Environment Using Vagrant
category: memo
slug: construct-your-freebsd-ports-testing-environment-using-vagrant
date: 2016-02-11
---
Nowadays, people who develops FreeBSD Ports are using automated tools, e.g.
[Poudriere](https://github.com/freebsd/poudriere), to deal with the complicated
procedures, including testing, packaging, and delivering. Because Windows sucks,
this tutorial uses Mac OS X as an example to illustrate the whole process you
will need to take to construct a FreeBSD Ports testing environment using
Vagrant.

## Homebrew

[Homebrew](http://brew.sh) is a mature package management system on Mac OS X. I
recommend using it to install all the third party packages you need on your Mac.
Also, it's worth mentioning the extension of Homebrew: Homebrew-Cask. Consider
using Homebrew-Cask to install and manage Mac GUI applications such as Goolge
Chrome and Firefox can make your life a little bit easier.

```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

After installed Homebrew, simply enter the following command to install a package:

```bash
brew install <name>
```

## VirtualBox

VirtualBox is an open source project which gives you the power to run virtual
machines right on your host, i.e. you Mac. Don't be confused VirtualBox with
Vagrant. Vagrant is a wrapped tool which let you bring up a VM without
complicated setup process, while VirtualBox being a underlying "provider" of
Vagrant. Of course you can use other "provider" like VMware Fusion to meet the
requirement of Vagrant, but we'll use VirtualBox in this tutorial.

```bash
brew cask install virtualbox
```

Only single one command, and you're done. The power of Homebrew-Cask!

## Vagrant

```bash
brew install vagrant
```

First, create a new directory and initialize it with Vagrant.

```bash
mkdir myfreebsd
cd myfreebsd
vagrant init
```

Under your Vagrant directory there is a Vagrant configuration file which called
`Vagrantfile`. The file is full of comments which could be very useful when you
don't know how to configure your Vagrant box. But we don't need it at this time.
Replace the content of the file with the following:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.synced_folder ".", "/vagrant", id: "vagrant-root", disabled: true
  config.vm.box = "freebsd/FreeBSD-10.2-RELEASE"
  config.ssh.shell = "sh"
  config.vm.base_mac = "080027D14C66"

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end
end
```

Fire up the VM with the config:

```bash
vagrant up
```

You can write your own shell script to provision the VM, or even use
[Ansible](http://www.ansible.com) to do the job. Simply run the following
command to do the provision work:

```bash
vagrant provision
```

## ZFS

Poudriere can benefit from ZFS. To enable ZFS on you VM, it is recommended to
set you VM's memory up to 4G or even larger. But the reality is, we don't have
that much memory available. We can still use ZFS with poor performance for
testing purpose.

Append the following line to `/etc/rc.conf` to enable ZFS on your FreeBSD VM:

```plaintext
zfs_enable="YES"
```

Load the ZFS kernel module by entering the following command:

```bash
sudo service zfs start
```

To lower the complexity of the tutorial, we don't attach another virtual disk to
the VM. There is an other way to achieve the goal using normal "file". Prepare a
big blank file to act as a hard drive. Create the zpool using the file we've
just created. And the rest will be done by Poudriere.

```bash
sudo dd if=/dev/zero of=/disk bs=1m count=8192
sudo zpool create ztank /disk
```

If you don't want to mess with ZFS, it's totally FINE to use UFS. Just skip this
section. And now we're good to go. Continue with Poudriere's settings.

## Poudriere

This how Poudriere is introduced in the FreeBSD handbook:

> Poudriere is a BSD-licensed utility for creating and testing FreeBSD packages.
> It uses FreeBSD jails to set up isolated compilation environments.

Use `pkg` utility to install Poudriere:

```bash
sudo pkg update -f
sudo pkg install -y poudriere
```

Like most of the software, there must be a bunch of configuration files to be
set up. Here comes `/usr/local/etc/poudriere.conf`! This file is also filled
with well explained directives. You can remove all the content because all we
need are listed as follow:

```text
# If "ZFS" is used
ZPOOL=tank
ZROOTFS=/poudriere

# If "UFS" is used
#NO_ZFS=yes

BASEFS=/poudriere
DISTFILES_CACHE=/tmp/DISTFILES
RESOLV_CONF=/etc/resolv.conf
FREEBSD_HOST=ftp://ftp.tw.freebsd.org
```

The directory of distfiles cache must be created before any build actions
happens:

```bash
sudo mkdir /tmp/DISTFILES
```

We're almost there! Next, prepare the jail which is used to build the packages
and the ports tree which is the source of our packages:

```bash
sudo poudriere jail -c -j 102amd64 -v 10.2-RELEASE -a amd64
sudo poudriere ports -c
```

Poudriere can only build certain version of packages according to the version of
the OS which the jail is running. For example, a 9.1-RELEASE jail can only build
the packages for 9.1-RELEASE hosts, not for 10.2-RELEASE.

The Ports tree will be named "default" because we didn't assign any name to it.

Finally we can start building the packages. To build one single port:

```bash
sudo poudriere bulk -j 102amd64 security/sudo
```

If you have a list of ports to build, just craft a list in this form:

```text
<category>/<portname>
<category>/<portname>
<category>/<portname>
...
```

Then bulk build with this list:

```bash
sudo poudriere bulk -j 102amd64 -f pkglist
```

Please be patient. The execution time depends on your host's compute power and
network performance. On my Macbook Air it take about 4~5 minutes to complete the
task (sudo package). And the newest packages will reside in
`/poudriere/data/packages/102amd64-default/All`.

## Integrate with Vagrant Provisioner

Follow the whole tutorial you get a complete environment which is capable
building FreeBSD packages for other FreeBSD workstations. Unfortunately, the
process may be repeated over and over again. What if one day you want to replace
ZFS with UFS? You may want to destroy the VM and start over again. That's quite
tedious. Trust me you'll be happier with Vagrant's provisioning feature. We will
start with the easiest provisioner, which is "shell script".

Insert a line specifying the provisioner in `Vagrantfile`:

```ruby
Vagrant.configure(2) do |config|

  ...

  config.vm.provision "shell", path: "provision.sh"

  ...

end
```

Then open and edit the shell script `provision.sh`:

```bash
#!/usr/bin/env sh

set -xe

pkg update -f
pkg install -y oudriere

cat >> /etc/rc.conf <<EOF
zfs_enable="YES"
EOF

service zfs start
dd if=/dev/zero of=/disk bs=1m count=8192
zpool create ztank /disk

cat > /usr/local/etc/poudriere.conf <<EOF
ZPOOL=tank
ZROOTFS=/poudriere
#NO_ZFS=yes
BASEFS=/poudriere
DISTFILES_CACHE=/tmp/DISTFILES
RESOLV_CONF=/etc/resolv.conf
FREEBSD_HOST=ftp://ftp.tw.freebsd.org
EOF

mkdir /tmp/DISTFILES

poudriere jail -c -j 102amd64 -v 10.2-RELEASE -a amd64
poudriere ports -c
```

You'll notice the content of the shell script are the steps we mentioned before
right in this tutorial. And we're all set, just start the VM as usual `vagrant
up`. After the VM booted up, Vagrant starts to provision the VM using the shell
script we specified in the `Vagrantfile`. It just that elegant! You can even use
configuration management system like Ansible to help make the provision task
more scalable and manageable.

## Summary

In this post I've tried to introduce how to construct a testing environment for
FreeBSD package bilding system right on your Mac in a more efficient way. The
build time may be longer though. The fully automated installation process works
like a charm. In a future post I will describe how the VMs created by Vagrant be
provisioned by Ansible.

Thanks for reading!

## References

-  [Official Vagrant FreeBSD Images][1]
-  [Testing the Port][2]
-  [How To Set Up a Poudriere Build System to Create Packages for your FreeBSD Servers][3]

[1]: https://forums.freebsd.org/threads/official-vagrant-freebsd-images.52717/
[2]: https://www.freebsd.org/doc/en/books/porters-handbook/testing-poudriere.html
[3]: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-poudriere-build-system-to-create-packages-for-your-freebsd-servers
