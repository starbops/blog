---
layout: post
title: 'Extending LVM Size with Multiple LUNs'
category: memo
slug: extending-lvm-size-with-multiple-luns
---
## Create New LUN with existing iSCSI Target on Synology

We can see there is already one LUN called **pve-vmimages** mapped to
pve-vmimages iSCSI target. Now create **pve-vmimages-ext** LUN and map it to the
same iSCSI target. The result should look like the following:

![Synology Disk
Manager](/assets/images/extending-lvm-size-with-multiple-luns/synology-disk-manager.png)

## Rescan for New LUN on Proxmox VE Hosts

```bash
root@pve1:~# iscsiadm --mode session --rescan
```

```bash
root@pve1:~# lvmdiskscan
  /dev/mapper/36d094660267abf0024ff75e573972158 [       4.91 TiB] LVM physical volume
  /dev/mapper/360014050e5db761da222d496ed8dd6d7 [       1.00 TiB]
  /dev/mapper/35000c500a0d6c0ef                 [       1.64 TiB]
  /dev/mapper/35000c500a0d688eb                 [       1.64 TiB]
  /dev/mapper/35000c500a0d68dbf                 [       1.64 TiB]
  /dev/mapper/35000c500a0d6a79b                 [       1.64 TiB]
  /dev/mapper/36001405a660c610d0d43d4ad7d80f6dd [       1.50 TiB] LVM physical volume
  /dev/sdi2                                     [     256.00 MiB]
  /dev/sdi3                                     [     445.75 GiB] LVM physical volume
  4 disks
  2 partitions
  1 LVM physical volume whole disk
  2 LVM physical volumes
```

```bash
root@pve1:~# pvcreate /dev/mapper/360014050e5db761da222d496ed8dd6d7
  Physical volume "/dev/mapper/360014050e5db761da222d496ed8dd6d7" successfully created.
```

```bash
root@pve1:~# lvmdiskscan -l
  WARNING: only considering LVM devices
  /dev/mapper/36d094660267abf0024ff75e573972158 [       4.91 TiB] LVM physical volume
  /dev/mapper/360014050e5db761da222d496ed8dd6d7 [       1.00 TiB] LVM physical volume
  /dev/mapper/36001405a660c610d0d43d4ad7d80f6dd [       1.50 TiB] LVM physical volume
  /dev/sdi3                                     [     445.75 GiB] LVM physical volume
  1 LVM physical volume whole disk
  3 LVM physical volumes
```

```bash
root@pve1:~# vgs
  VG  #PV #LV #SN Attr   VSize VFree
  pve   2  16   0 wz--n- 5.35t     0
  vms   1  38   0 wz--n- 1.50t 62.00g
```

```bash
root@pve1:~# vgextend vms /dev/mapper/360014050e5db761da222d496ed8dd6d7
  Volume group "vms" successfully extended
```

```bash
root@pve1:~# vgs
  VG  #PV #LV #SN Attr   VSize VFree
  pve   2  16   0 wz--n- 5.35t    0
  vms   2  38   0 wz--n- 2.50t 1.06t
```

## References

-  [Chapter 36. Scanning iSCSI Targets with Multiple LUNs or Portals Red Hat
   Enterprise Linux 6 | Red Hat Customer
   Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/storage_administration_guide/iscsi-scanning-interconnects)
-  [iSCSI Shared Storage Resize whilst system still
   live](https://forum.proxmox.com/threads/iscsi-shared-storage-resize-whilst-system-still-live.37955/)
-  [Resizing storage LUNs in Linux on the
   fly](https://standalone-sysadmin.com/resizing-storage-luns-in-linux-on-the-fly-cb233dd8c8ce)
