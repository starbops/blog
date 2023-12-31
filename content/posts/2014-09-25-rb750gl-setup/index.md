---
title: RB750GL Setup
category: memo
slug: rb750gl-setup
date: 2014-09-25
---
Build my own environment for network experiment!

I want to make an environment for developing and testing. And that environment
totally belongs to me.

## Scenario

-  RouterBOARD RB750GL
   -  MikroTik RouterOS 5.25
-  PC
   -  XenServer 6.2

```text
 mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
E                                                       3
E                        Internet                       3
E                                                       3
 wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
    |
    |
    |
    |
    |                                    +----+   +----+
    | 10.113.215.193/24                  | VM |...| VM |
+---+----------+                        ++----+---+----++
|   1          |  (DHCP, NAT)           |               |
| (Gateway)   2+------------------------+               |
|             3| 192.168.88.1/24        |      PC       |
|             4|                        |   XenServer   |
|  RB750GL    5|                        |               |
|              |                        |               |
+--------------+                        +---------------+
                                        192.168.88.154/24
```

## Connect with Internet

Configure IP address, gateway and DNS server

```bash
/ip address add address=10.113.215.193/24 interface=ether1-gateway
/ip route add dst-address=0.0.0.0/0 gateway=ether1-gateway
/ip dns set servers=10.113.235.1,8.8.8.8
```

To test connectivity, try to do this

```bash
/tool flood-ping 8.8.8.8
```

## NTP (Network Time Protocol)

Synchronize time with 3.asia.pool.ntp.org using NTP

```bash
/system ntp client set enabled=yes mode=unicast primary-ntp=77.235.14.49 secondary-ntp=212.26.18.43
```

To verify that NTP client is running

```bash
/system ntp client print
```

## Upgrade RouterOS

Check what version RB750GL is running currently

```bash
/system package update print
```

Update RouterOS from 5.25 to 5.26

```bash
/system package update check-for-updates
/system package update download
```

By issuing `/system package update print` you'll see the percentage of download
progress. When it is done, upgrade the OS

```bash
/system package update upgrade
```

RB750GL will auto reboot immediately. When it is ready, ssh into it you'll see

```text
MMM      MMM       KKK                          TTTTTTTTTTT      KKK
MMMM    MMMM       KKK                          TTTTTTTTTTT      KKK
MMM MMMM MMM  III  KKK  KKK  RRRRRR     OOOOOO      TTT     III  KKK  KKK
MMM  MM  MMM  III  KKKKK     RRR  RRR  OOO  OOO     TTT     III  KKKKK
MMM      MMM  III  KKK KKK   RRRRRR    OOO  OOO     TTT     III  KKK KKK
MMM      MMM  III  KKK  KKK  RRR  RRR   OOOOOO      TTT     III  KKK  KKK

MikroTik RouterOS 5.26 (c) 1999-2013       http://www.mikrotik.com/
```

The upgrading procedure was done successfully.

## DHCP (Dynamic Host Configuration Protocol) Server

Giving XenServer a static IP

```bash
/ip dhcp-server lease add address=192.168.88.154 mac-address=f4:6d:04:79:80:ff
```

## Firewall

There were bunch of rules set already. If there were not, you can try these

```bash
/ip firewall filter add action=accept chain=input comment="default configuration" disabled=no protocol=icmp
/ip firewall filter add action=accept chain=input comment="default configuration" connection-state=established disabled=no
/ip firewall filter add action=accept chain=input comment="default configuration" connection-state=related disabled=no
/ip firewall filter add action=drop chain=input comment="default configuration" disabled=no in-interface=ether1-gateway
/ip firewall filter add action=accept chain=forward comment="default configuration" connection-state=established disabled=no
/ip firewall filter add action=accept chain=forward comment="default configuration" connection-state=related disabled=no
/ip firewall filter add action=drop chain=forward comment="default configuration" connection-state=invalid disabled=no
```

Reminder: **Firewall rules are traversed in order.**

## NAT (Network Address Translation)

To allow VMs inside LAN have full access to the Internet, one thing to do is
masquerade packets send to the outer network

```bash
/ip firewall nat add action=masquerade chain=srcnat comment="default configuration" disabled=no out-interface=ether1-gateway
```

If you want remote client to access internal services, e.g. SSH, HTTP, RDP, etc.,
destination NAT is needed

```bash
/ip firewall nat add action=dst-nat chain=dstnat disabled=no dst-port=2222 in-interface=ether1-gateway protocol=tcp to-addresses=192.168.88.155 to-ports=22
```

## VPN (Virtual Private Network) Server

Setting up PPTP (Point-to-Point Tunneling Protocol) server. First, we need to
allocate a IP pool for VPN clients

```bash
/ip pool add name=pptp_pool1 range=192.168.88.5-192.168.88.9

/ppp profile add name=pptp_profile local-address=192.168.88.1 remote-address=pptp_pool1
/ppp secret add name=doreremimi password=51402991 service=pptp profile=pptp_profile
/interface pptp-server server set enable=yes
```

After the setting was done, the connection of VPN should be allowed through the
firewall

```bash
/ip firewall filter add chain=input in-interface=ether1-gateway protocol=tcp dst-port=1723 action=accept
```

The connection states could be checked throuth this command

```bash
/interface pptp-server monitor
```

Now, VPN clients can only ping RB750GL's LAN IP. If you want to communicate
with other PCs or servers in the LAN, one thing you have to do is enabling
proxy ARP on the local port

```bash
/interface ethernet set ether2-master-local arp=proxy-arp
```

## References

-  [MikroTik Wiki](http://wiki.mikrotik.com/wiki/Main_Page)
-  [基地台與分享器 - [研究所] MikroTik RouterOS 學習 (持續更新) - 電腦討論區 - Mobile01](http://www.mobile01.com/topicdetail.php?f=110&t=3205444)
