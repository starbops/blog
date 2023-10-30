---
title: Tricky Network Issue in KCPS-Baremetal Testbed
category: memo
slug: tricky-network-issue-in-kcps-baremetal-testbed
date: 2019-07-23
---
This tricky network issue consists of:

-  Subnet overlapping
-  ARP request not ignored
-  Proxy ARP race condition
-  Asymmetric routing

## arp_ignore

```text
arp_ignore - INTEGER
        Define different modes for sending replies in response to
        received ARP requests that resolve local target IP addresses:
        0 - (default): reply for any local target IP address, configured
        on any interface
        1 - reply only if the target IP address is local address
        configured on the incoming interface
        2 - reply only if the target IP address is local address
        configured on the incoming interface and both with the
        sender's IP address are part from same subnet on this interface
        3 - do not reply for local addresses configured with scope host,
        only resolutions for global and link addresses are replied
        4-7 - reserved
        8 - do not reply for all local addresses

        The max value from conf/{all,interface}/arp_ignore is used
        when ARP request is received on the {interface}
```

## Proxy ARP

> Though not the best practice, you can design a network to use one subnet on
> multiple VLANs and use routers with proxy ARP enabled to forward traffic
> between hosts in those VLANs.

## Proxy ARP Disabled at VLAN 5 Interface

```bash
Dst3650X#sh ip int vlan5 | i Proxy
  Proxy ARP is disabled
  Local Proxy ARP is disabled
```

```bash
[haas@haas ~]$ brctl show
bridge name     bridge id               STP enabled     interfaces
br1             8000.008cfaef7e3a       no              eth0
[haas@haas ~]$ arping -f -I br1 10.5.168.168
ARPING 10.5.168.168 from 10.5.131.1 br1
Unicast reply from 10.5.168.168 [00:25:90:CA:62:04]  0.785ms
Sent 1 probes (1 broadcast(s))
Received 1 response(s)
```

```bash
[root@BAMPI ~]# tcpdump -i eth0.5 -en arp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0.5, link-type EN10MB (Ethernet), capture size 65535 bytes
12:01:12.900997 00:8c:fa:ef:7e:3a > Broadcast, ethertype ARP (0x0806), length 60: Request who-has 10.5.168.168 (Broadcast) tell 10.5.131.1, length 46
12:01:12.901030 00:25:90:ca:62:04 > 00:8c:fa:ef:7e:3a, ethertype ARP (0x0806), length 42: Reply 10.5.168.168 is-at 00:25:90:ca:62:04, length 28
^C
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

## Proxy ARP Enabled at VLAN 5 Interface

```bash
[root@BAMPI ~]# tcpdump -i eth0.5 -en arp | grep "0.254"
...
14:23:40.983008 80:71:1f:4c:be:01 > Broadcast, ethertype ARP (0x0806), length 60: Request who-has 10.5.1.20 tell 10.5.0.254, length 46
...
^C326 packets captured
326 packets received by filter
0 packets dropped by kernel
```

## rp_filter

```text
rp_filter - INTEGER
        0 - No source validation.
        1 - Strict mode as defined in RFC3704 Strict Reverse Path
            Each incoming packet is tested against the FIB and if the interface
            is not the best reverse path the packet check will fail.
            By default failed packets are discarded.
        2 - Loose mode as defined in RFC3704 Loose Reverse Path
            Each incoming packet's source address is also tested against the FIB
            and if the source address is not reachable via any interface
            the packet check will fail.

        Current recommended practice in RFC3704 is to enable strict mode
        to prevent IP spoofing from DDos attacks. If using asymmetric routing
        or other complicated routing, then loose mode is recommended.

        The max value from conf/{all,interface}/rp_filter is used
        when doing source validation on the {interface}.

        Default value is 0. Note that some distributions enable it
        in startup scripts.
```

`rp_filter` stands for reverse path filtering. The reverse path filter will
check if the source of a packet that was received on a certain interface is
reachable through the same interface it was received. The purpose is to prevent
spoofed packets, with a changed source address, not being processed/routed
further. In a router it could also prevent routing packets that have a private
IP address as source to the internet as they obviously will never find their way
back.

## References

-  [Proxy ARP - Cisco](https://www.cisco.com/c/en/us/support/docs/ip/dynamic-address-allocation-resolution/13718-5.html)
-  [/proc/sys/net/ipv4/* Variables](https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
-  [How to broadcast ARP update to all neighbors in Linux?](https://serverfault.com/questions/175803/how-to-broadcast-arp-update-to-all-neighbors-in-linux/175806)
-  [ARP Table Timeout and MAC-Address-Table Timeout](https://learningnetwork.cisco.com/thread/2450)
-  [Using the Linux arping utility to send out gratuitious ARPs](https://prefetch.net/blog/2011/03/26/using-the-linux-arping-utility-to-send-out-gratuitious-arps/)
-  [Solved: Proxy-Arp - Cisco Support Community](https://supportforums.cisco.com/t5/wan-routing-and-switching/proxy-arp/td-p/1560798)
-  [Configure two network cards in a different subnet on RHEL 6, RHEL 7, CentOS
   6 and CentOS 7](http://jensd.be/468/linux/two-network-cards-rp_filter)
-  [Linux does not reply to ARP request messages if requested IP address is
   associated with another (disabled)
   interface](https://unix.stackexchange.com/questions/205708/linux-does-not-reply-to-arp-request-messages-if-requested-ip-address-is-associat)
