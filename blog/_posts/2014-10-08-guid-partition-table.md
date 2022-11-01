---
layout: post
title: 'GUID Partition Table'
category: memo
slug: guid-partition-table
---
System Administration GUID Partition Table Note

## Introduction

-  MBR and GPT are partition schemes
   -  GPT is a standard for the layout of the partition table on a physical
      hard disk, using globally unique identifiers (GUID).
-  UEFI <-> GPT, BIOS <-> MBR

## Master Boot Record (MBR)

### Structure

The Master Boot Record (MBR) is the first 512 bytes of a storage device. It
contains:

-  An operating system bootloader - 446 bytes
-  The storage device's partition table (4 primary partitions) - 64 bytes
-  MBR boot signature (0xAA55) - 2 bytes

### Constraints

-  4 primary partition or 3 primary + 1 extended partitions
   -  Arbitrary number of logical partitions within the extended partition
-  The logical partition meta-data is stored in a linked-list structure.
-  One byte partition type codes which leads to many collisions
-  Maximum addressable size is 2 TiB, i.e. any space beyond 2 TiB cannot be
   defined as a partition
   -  MBR stores partition sector information using 32-bit LBA values
   -  512 bytes per sector
   -  512 bytes * (2^32) = 2 TiB

### Booting Process

-  System initialization with firmware called BIOS
-  The BIOS looks for the bootloader on the MBR of the first storage device or
   the first partition of the device, then executes it
-  Bootloader reads the partition table
   -  Conventional Windows/DOS MBR bootlaoder will check the partition table
      for one and only one active and primary partition
   -  GRUB safely ignores this
-  Loading Operating system

-  Common GNU/Linux bootloader include GRUB and Syslinux

## Unified Extensible Firmware Interface (UEFI)

-  To replace BIOS
-  Provides legecy support for BIOS
-  The original EFI specification was developed by Intel
-  The UEFI specfication is managed by the Unified EFI forum
-  Micro operating system
-  Graphical User Interface
-  Secure Computing (evil)

## GUID Partition Table (GPT)

-  GUID stands for Globally Unique Identifier
-  Part of the UEFI specification
-  Solves some legacy problems with MBR but also may have compatibility
   issues.
-  Can be used also on BIOS system via a protective MBR

### Advantages

-  Up to 18 EB (1 EB = 1024 TB) ?
-  No partition type collision because of GUIDs
-  8 ZiB
   -  GPT uses 64-bit LBA
   -  512 bytes per sector
   -  512 bytes * (2^64) = 8 ZiB

## Tools

-  fdisk
-  gdisk
-  parted
-  gpart
