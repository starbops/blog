---
layout: post
title: 'Adding Virtual Disks From XenServer CLI'
category: memo
slug: add-virtual-disk-from-xe-cli
---
I don't know where and when I set this, but XenCenter keeps telling me that I
cannot add more virtual disks (currently only 3 virtual disks) to my virtual
machine.

```
You have reached the maximum number of virtual disks allowed for this
virtual machine.
```

But I can create a virtual disk and attach it to the virtual machine via XE
command line. First, get the UUID of the local storage repository:

```bash
[root@zenserv ~]# xe sr-list name-label="Local storage"
uuid ( RO)                : 20f9d73a-f1e5-be80-2fcc-a9863d4112ac
          name-label ( RW): Local storage
    name-description ( RW):
                host ( RO): zenserv
                type ( RO): lvm
        content-type ( RO): user
```

Then get the UUID of the virtual machine to which the new virtual disk will
attach:

```bash
[root@zenserv ~]# xe vm-list name-label=zphome
uuid ( RO)           : ba73ef4f-ad8a-91c9-a9d8-ebea92f5081f
     name-label ( RW): zphome
    power-state ( RO): halted
```

Having the UUID of the storage repository, we then create the virtual disk
(VDI). The only one line return string is the UUID of the newly created virtual
disk. Copy it because it will be used in the following steps.

```bash
[root@zenserv ~]# xe vdi-create \
> sr-uuid=20f9d73a-f1e5-be80-2fcc-a9863d4112ac \
> name-label=zphome_disk3 \
> type=user virtual-size=107374182400
a65be954-b7a4-44ec-9603-4c2275e1d1f8
```

Create virtual block device (VBD) that connects the VDI to the VM:

```bash
[root@zenserv ~]# xe vbd-create \
> vm-uuid=ba73ef4f-ad8a-91c9-a9d8-ebea92f5081f device=3
> vdi-uuid=a65be954-b7a4-44ec-9603-4c2275e1d1f8 \
> bootable=false mode=RW type=Disk
ce5f0688-ff5f-fb1b-0196-7cd836b639d9
```

Activate the VBD:

```bash
[root@zenserv ~]# xe vbd-plug uuid=ce5f0688-ff5f-fb1b-0196-7cd836b639d9
You attempted an operation on a VM that was not in an appropriate power
state at the time; for example, you attempted to start a VM that was
already running.  The parameters returned are the VM's handle, and the
expected and actual VM state at the time of the call.
vm: ba73ef4f-ad8a-91c9-a9d8-ebea92f5081f (zphome)
expected: running
actual: halted
```

Check the VBD:

```bash
[root@zenserv ~]# xe vbd-list vm-name-label=zphome
...output suppressed...

uuid ( RO)             : ce5f0688-ff5f-fb1b-0196-7cd836b639d9
          vm-uuid ( RO): ba73ef4f-ad8a-91c9-a9d8-ebea92f5081f
    vm-name-label ( RO): zphome
         vdi-uuid ( RO): a65be954-b7a4-44ec-9603-4c2275e1d1f8
            empty ( RO): false
           device ( RO):
```

Now you should be able to see the fourth virtual disk listed on the "Storage"
page of the virtual machine in XenCenter.

## Reference

- [XenServer - Create and Attach Virtual Disk from XE CLI][1]

[1]: https://techhelplist.com/index.php/tech-tutorials/41-misc/316-xenserver-create-and-attach-virtual-disk-from-xe-cli
