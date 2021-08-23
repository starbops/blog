---
layout: post
title: 'Extending LVM Size with New Disk Added'
category: note
slug: extending-lvm-size-with-new-disk-added
---

```bash
root@pve1:~# lvmdiskscan
  /dev/mapper/36d094660267abf0024ff75e573972158 [       4.91 TiB]
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
  1 LVM physical volume
```

```bash
root@pve1:~# pvcreate /dev/mapper/36d094660267abf0024ff75e573972158
  Physical volume "/dev/mapper/36d094660267abf0024ff75e573972158" successfully created.
```

```bash
root@pve1:~# lvmdiskscan -l
  WARNING: only considering LVM devices
  /dev/mapper/36d094660267abf0024ff75e573972158 [       4.91 TiB] LVM physical volume
  /dev/mapper/36001405a660c610d0d43d4ad7d80f6dd [       1.50 TiB] LVM physical volume
  /dev/sdi3                                     [     445.75 GiB] LVM physical volume
  1 LVM physical volume whole disk
  2 LVM physical volumes
```

```bash
root@pve1:~# vgs
  VG  #PV #LV #SN Attr   VSize   VFree
  pve   1  16   0 wz--n- 445.75g 15.83g
  vms   1  38   0 wz--n-   1.50t 62.00g
root@pve1:~# vgextend pve /dev/mapper/36d094660267abf0024ff75e573972158
  Volume group "pve" successfully extended
root@pve1:~# vgs
  VG  #PV #LV #SN Attr   VSize VFree
  pve   2  16   0 wz--n- 5.35t  4.93t
  vms   1  38   0 wz--n- 1.50t 62.00g
```

```bash
root@pve1:~# lvs
  LV              VG  Attr       LSize   Pool Origin          Data%  Meta%  Move Log Cpy%Sync Convert
  base-777-disk-1 pve Vri---tz-k  32.00g data
  data            pve twi-aotz-- 325.75g                      93.02  44.37
  root            pve -wi-ao----  96.00g
  swap            pve -wi-ao----   8.00g
  vm-106-disk-1   pve Vwi-a-tz--  10.00g data                 63.33
  vm-107-disk-1   pve Vwi-a-tz--  16.00g data                 62.86
  vm-109-disk-1   pve Vwi-a-tz--  30.00g data                 84.62
  vm-110-disk-1   pve Vwi-a-tz--  32.00g data                 62.48
  vm-201-disk-1   pve Vwi-a-tz--  32.00g data                 3.49
  vm-311-disk-1   pve Vwi-a-tz-- 128.00g data                 16.40
  vm-602-disk-1   pve Vwi-a-tz--  32.00g data                 33.05
  vm-608-disk-1   pve Vwi-a-tz--  32.00g data                 73.42
  vm-666-disk-1   pve Vwi-a-tz-- 128.00g data                 93.53
  vm-756-disk-1   pve Vwi-a-tz--  32.00g data                 86.77
  vm-762-disk-1   pve Vwi-a-tz--  32.00g data                 84.00
  vm-778-disk-1   pve Vwi-a-tz--  32.00g data base-777-disk-1 32.24
  vm-100-disk-1   vms -wi-------  10.00g
  vm-101-disk-1   vms -wi-------  32.00g
  vm-117-disk-1   vms -wi------- 200.00g
  vm-151-disk-1   vms -wi-------  32.00g
  vm-152-disk-1   vms -wi-------  32.00g
  vm-200-disk-1   vms -wi------- 200.00g
  vm-300-disk-1   vms -wi-------  16.00g
  vm-301-disk-1   vms -wi-------  32.00g
  vm-302-disk-1   vms -wi-------  16.00g
  vm-313-disk-1   vms -wi-------  64.00g
  vm-323-disk-1   vms -wi-------  10.00g
  vm-601-disk-1   vms -wi-------  16.00g
  vm-601-disk-2   vms -wi-------  64.00g
  vm-602-disk-1   vms -wi-------  32.00g
  vm-603-disk-1   vms -wi-------  16.00g
  vm-603-disk-2   vms -wi-------  32.00g
  vm-604-disk-1   vms -wi-------  12.00g
  vm-605-disk-1   vms -wi-------  12.00g
  vm-606-disk-1   vms -wi-------  16.00g
  vm-606-disk-2   vms -wi-------  16.00g
  vm-606-disk-3   vms -wi-------  16.00g
  vm-607-disk-1   vms -wi-------  16.00g
  vm-607-disk-2   vms -wi-------  16.00g
  vm-607-disk-3   vms -wi-------  16.00g
  vm-611-disk-1   vms -wi-------  16.00g
  vm-611-disk-2   vms -wi-------  64.00g
  vm-612-disk-1   vms -wi-------  16.00g
  vm-612-disk-2   vms -wi-------  64.00g
  vm-621-disk-1   vms -wi-------  16.00g
  vm-650-disk-1   vms -wi------- 200.00g
  vm-996-disk-1   vms -wi-------  50.00g
  vm-997-disk-1   vms -wi-------  16.00g
  vm-998-disk-1   vms -wi-------  50.00g
  vm-998-disk-2   vms -wi-------   2.00g
  vm-998-disk-3   vms -wi-------   2.00g
  vm-999-disk-1   vms -wi-------  50.00g
  vm-999-disk-2   vms -wi-------   2.00g
  vm-999-disk-3   vms -wi-------   2.00g
root@pve1:~# lvextend -l +100%FREE pve/data
  Size of logical volume pve/data_tdata changed from 325.75 GiB (83392 extents) to 5.24 TiB (1374708 extents).
  Logical volume pve/data_tdata successfully resized.
root@pve1:~# lvs
  LV              VG  Attr       LSize   Pool Origin          Data%  Meta%  Move Log Cpy%Sync Convert
  base-777-disk-1 pve Vri---tz-k  32.00g data
  data            pve twi-aotz--   5.24t                      5.64   50.33
  root            pve -wi-ao----  96.00g
  swap            pve -wi-ao----   8.00g
  vm-106-disk-1   pve Vwi-a-tz--  10.00g data                 63.33
  vm-107-disk-1   pve Vwi-a-tz--  16.00g data                 62.86
  vm-109-disk-1   pve Vwi-a-tz--  30.00g data                 84.62
  vm-110-disk-1   pve Vwi-a-tz--  32.00g data                 62.48
  vm-201-disk-1   pve Vwi-a-tz--  32.00g data                 3.49
  vm-311-disk-1   pve Vwi-a-tz-- 128.00g data                 16.40
  vm-602-disk-1   pve Vwi-a-tz--  32.00g data                 33.05
  vm-608-disk-1   pve Vwi-a-tz--  32.00g data                 73.42
  vm-666-disk-1   pve Vwi-a-tz-- 128.00g data                 93.53
  vm-756-disk-1   pve Vwi-a-tz--  32.00g data                 86.77
  vm-762-disk-1   pve Vwi-a-tz--  32.00g data                 84.00
  vm-778-disk-1   pve Vwi-a-tz--  32.00g data base-777-disk-1 32.24
  vm-100-disk-1   vms -wi-------  10.00g
  vm-101-disk-1   vms -wi-------  32.00g
  vm-117-disk-1   vms -wi------- 200.00g
  vm-151-disk-1   vms -wi-------  32.00g
  vm-152-disk-1   vms -wi-------  32.00g
  vm-200-disk-1   vms -wi------- 200.00g
  vm-300-disk-1   vms -wi-------  16.00g
  vm-301-disk-1   vms -wi-------  32.00g
  vm-302-disk-1   vms -wi-------  16.00g
  vm-313-disk-1   vms -wi-------  64.00g
  vm-323-disk-1   vms -wi-------  10.00g
  vm-601-disk-1   vms -wi-------  16.00g
  vm-601-disk-2   vms -wi-------  64.00g
  vm-602-disk-1   vms -wi-------  32.00g
  vm-603-disk-1   vms -wi-------  16.00g
  vm-603-disk-2   vms -wi-------  32.00g
  vm-604-disk-1   vms -wi-------  12.00g
  vm-605-disk-1   vms -wi-------  12.00g
  vm-606-disk-1   vms -wi-------  16.00g
  vm-606-disk-2   vms -wi-------  16.00g
  vm-606-disk-3   vms -wi-------  16.00g
  vm-607-disk-1   vms -wi-------  16.00g
  vm-607-disk-2   vms -wi-------  16.00g
  vm-607-disk-3   vms -wi-------  16.00g
  vm-611-disk-1   vms -wi-------  16.00g
  vm-611-disk-2   vms -wi-------  64.00g
  vm-612-disk-1   vms -wi-------  16.00g
  vm-612-disk-2   vms -wi-------  64.00g
  vm-621-disk-1   vms -wi-------  16.00g
  vm-650-disk-1   vms -wi------- 200.00g
  vm-996-disk-1   vms -wi-------  50.00g
  vm-997-disk-1   vms -wi-------  16.00g
  vm-998-disk-1   vms -wi-------  50.00g
  vm-998-disk-2   vms -wi-------   2.00g
  vm-998-disk-3   vms -wi-------   2.00g
  vm-999-disk-1   vms -wi-------  50.00g
  vm-999-disk-2   vms -wi-------   2.00g
  vm-999-disk-3   vms -wi-------   2.00g
```

## References

-  [How to add an extra second hard drive on Linux LVM and increase the size of
   storage -
   nixCraft](https://www.cyberciti.biz/faq/howto-add-disk-to-lvm-volume-on-linux-to-increase-size-of-pool/)
