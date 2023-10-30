---
title: Extending Metadata Space of LVM Thin Provisioning
category: note
slug: extending-metadata-space-of-lvm-thin-provisioning
date: 2020-02-12
---
Firstly, expand RAID 5 by adding a new hard drive into it. It will take about 1
day to reconstruct the RAID, so please be patient.

```bash
root@pve2:~# pvresize -v /dev/mapper/36d0946603cb2db0024e931c9a882ced7
    Wiping internal VG cache
    Wiping cache of LVM-capable devices
    Archiving volume group "pve" metadata (seqno 446).
    Resizing volume "/dev/mapper/36d0946603cb2db0024e931c9a882ced7" to 10545266688 sectors.
    No change to size of physical volume /dev /mapper/36d0946603cb2db0024e931c9a882ced7.
    Updating phycal volume "/dev/mapper/36d0946603cb2db0024e931c9a882ced7"
    Creating volume group backup "/etc/lvm/backup/pve" (seqno 447).
  Physical volume "/dev/mapper/36d0946603cb2db0024e931c9a882ced7" changed
  1 physical volume(s) resized / 0 physical volume(s) not resized
```

---

```bash
root@pve1:~# pvs
  PV                                            VG  Fmt  Attr PSize    PFree
  /dev/mapper/360014054018ff8ed35f0d4277da271d2 vms lvm2 a--  1024.00g 896.00g
  /dev/mapper/36001405a660c610d0d43d4ad7d80f6dd vms lvm2 a--     1.50t  30.00g
  /dev/mapper/36d094660267abf0024ff75e573972158 pve lvm2 a--     4.91t      0
  /dev/sde3                                     pve lvm2 a--   445.75g      0
```

```bash
root@pve1:~# pvresize -v /dev/mapper/36d094660267abf0024ff75e573972158
    Wiping internal VG cache
    Wiping cache of LVM-capable devices
    Archiving volume group "pve" metadata (seqno 218).
    Resizing volume "/dev/mapper/36d094660267abf0024ff75e573972158" to 10545266688 sectors.
    No change to size of physical volume /dev/mapper/36d094660267abf0024ff75e573972158.
    Updating physical volume "/dev/mapper/36d094660267abf0024ff75e573972158"
    Creating volume group backup "/etc/lvm/backup/pve" (seqno 219).
  Physical volume "/dev/mapper/36d094660267abf0024ff75e573972158" changed
  1 physical volume(s) resized / 0 physical volume(s) not resized
```

Reboot

```bash
root@pve1:~# pvresize -v /dev/mapper/36d094660267abf0024ff75e573972158
    Wiping internal VG cache
    Wiping cache of LVM-capable devices
    Archiving volume group "pve" metadata (seqno 219).
    Resizing volume "/dev/mapper/36d094660267abf0024ff75e573972158" to 14060355584 sectors.
    Resizing physical volume /dev/mapper/36d094660267abf0024ff75e573972158 from 0 to 1716351 extents.
    Updating physical volume "/dev/mapper/36d094660267abf0024ff75e573972158"
    Creating volume group backup "/etc/lvm/backup/pve" (seqno 220).
  Physical volume "/dev/mapper/36d094660267abf0024ff75e573972158" changed
  1 physical volume(s) resized / 0 physical volume(s) not resized
```

```bash
root@pve1:~# vgs
  VG  #PV #LV #SN Attr   VSize VFree
  pve   2  13   0 wz--n- 6.98t   1.64t
  vms   2  42   0 wz--n- 2.50t 925.99g
```

The following command will deactivate all LVs under LVM thin provisioning pool
`data`, so you won't see them listed under `/dev/mapper` again. By doing this,
we minimize the impact to the thin provisioning pool while we're resizing the
metadata space.

```bash
root@pve1:~# for lv in $(lvdisplay | grep -iE "lv pool name.*data" -B6 | grep -i "lv path" | awk '{print $3}' | xargs); do lvchange -an -v $lv; sleep 1; done
    Deactivating logical volume pve/vm-106-disk-1.
    Removing pve-vm--106--disk--1 (253:7)
    Deactivating logical volume pve/vm-107-disk-1.
    Removing pve-vm--107--disk--1 (253:8)
    Deactivating logical volume pve/vm-109-disk-1.
    Removing pve-vm--109--disk--1 (253:9)
    Deactivating logical volume pve/vm-756-disk-1.
    Removing pve-vm--756--disk--1 (253:10)
    Deactivating logical volume pve/vm-762-disk-1.
    Removing pve-vm--762--disk--1 (253:11)
    Deactivating logical volume pve/vm-110-disk-1.
    Removing pve-vm--110--disk--1 (253:12)
    Deactivating logical volume pve/base-777-disk-1.
    Deactivating logical volume pve/vm-201-disk-1.
    Removing pve-vm--201--disk--1 (253:13)
    Deactivating logical volume pve/vm-113-disk-1.
    Removing pve-vm--113--disk--1 (253:14)
    Deactivating logical volume pve/snap_vm-113-disk-1_clean_slate.
```

```bash
root@pve1:~# lvresize --poolmetadatasize +1G pve/data
  Size of logical volume pve/data_tmeta changed from 84.00 MiB (21 extents) to 1.08 GiB (277 extents).
  Logical volume pve/data_tmeta successfully resized.
```

```bash
root@pve1:~# lvchange -ay -v pve/data
    Activating logical volume pve/data exclusively.
    activation/volume_list configuration setting not defined: Checking only host tags for pve/data.
    Creating pve-data_tmeta
    Loading pve-data_tmeta table (253:3)
    Resuming pve-data_tmeta (253:3)
    Creating pve-data_tdata
    Loading pve-data_tdata table (253:4)
    Resuming pve-data_tdata (253:4)
    Executing: /usr/sbin/thin_check -q --clear-needs-check-flag /dev/mapper/pve-data_tmeta
    Creating pve-data-tpool
    Loading pve-data-tpool table (253:5)
    Resuming pve-data-tpool (253:5)
    Creating pve-data
    Loading pve-data table (253:6)
    Resuming pve-data (253:6)
    Monitoring pve/data
```

Activating all related LVs we that just deactivated:

```bash
root@pve1:~# lvchange -ay -v /dev/pve/vm-106-disk-1
    Activating logical volume pve/vm-106-disk-1 exclusively.
    activation/volume_list configuration setting not defined: Checking only host tags for pve/vm-106-disk-1.
    Loading pve-data_tdata table (253:4)
    Suppressed pve-data_tdata (253:4) identical table reload.
    Loading pve-data_tmeta table (253:3)
    Suppressed pve-data_tmeta (253:3) identical table reload.
    Loading pve-data-tpool table (253:5)
    Suppressed pve-data-tpool (253:5) identical table reload.
    Creating pve-vm--106--disk--1
    Loading pve-vm--106--disk--1 table (253:7)
    Resuming pve-vm--106--disk--1 (253:7)
    pve/data already monitored.
...
```

Reboot

## References

-  [What is this dm-0
   device?](https://superuser.com/questions/131519/what-is-this-dm-0-device)
-  [Repair a thin
   pool](https://medium.com/@unxrlm/repair-a-thin-pool-a42f41169541)
-  [jthornber/thin-provisioning-tools](https://github.com/jthornber/thin-provisioning-tools)
-  [LVM Metadata
   Repair](https://charlmert.github.io/blog/2017/06/15/lvm-metadata-repair/)
