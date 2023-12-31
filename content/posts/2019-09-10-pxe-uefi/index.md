---
title: PXE UEFI
category: memo
slug: pxe-uefi
date: 2019-09-10
---
## GRUB

In file `/etc/dhcp/dhcpd.conf`:

```bash
ddns-update-style interim;
        allow booting;
        allow bootp;
        ignore client-updates;
        set vendorclass = option vendor-class-identifier;
        option pxe-system-type code 93 = unsigned integer 16;

subnet 10.190.21.0 netmask 255.255.255.0{}
subnet 10.190.21.0 netmask 255.255.255.0 {
    default-lease-time         2160000;
    max-lease-time             432000;
    option routers             10.190.21.254;
    next-server                10.190.21.10;

host tiogapass-1{hardware ethernet 00:22:4d:d0:10:92; fixed-address 10.190.21.2;}
class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    if option pxe-system-type = 00:02 {
            filename "ia64/elilo.efi";
    } else if option pxe-system-type = 00:06 {
            filename "grub/grub-x86.efi";
    } else if option pxe-system-type = 00:07 {
            filename "grub/grubnetx64.efi.signed";
    } else {
            filename "pxelinux.0";
    }
  }
}##10.190.21.0##
```

In file `/var/lib/tftpboot/grub/grub.cfg`:

```bash
default=0
timeout=1

menuentry 'disposable_os' {
    linuxefi /images/disposableos/live/vmlinuz boot=live username=user config noswap locales= edd=on nomodeset noprompt union=overlay components ocs_daemonon="ssh" ocs_live_run="sudo sh /opt/boot/boot_main.sh tiogapass-1 10.190.11.10 live" ocs_live_extra_param="" keyboard-layouts=NONE ocs_live_keymap="NONE" ocs_live_batch="yes" ocs_lang="en_US.UTF-8" ip= net.ifnames=0 nosplash fetch=http://10.190.11.10:8080/fs/filesystem.squashfs bmpcfg_10.190.21.2_255.255.255.0_10.190.21.10_00:22:4d:d0:10:92
    initrdefi /images/disposableos/live/initrd.img
}
```

## References

-  [10.4. Providing and configuring bootloaders for PXE clients](https://docs.fedoraproject.org/en-US/Fedora/24/html/Installation_Guide/pxe-bootloader.html)
-  [30.2.2. Configuring PXE Boot for EFI Red Hat Enterprise Linux 6 \| Red Hat
   Customer
   Portal](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/installation_guide/s1-netboot-pxe-config-efi)
