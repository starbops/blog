---
layout: post
title: 'Linux HA Redundant Ring Protocol'
category: memo
slug: linux-ha-redundant-ring-protocol
---
## Introduction

Corosync is the messaging layer inside your cluster. It is responsable for several things like:

- Cluster membership and messaging thanks to the Totem Single Ring Ordering and Membership protocol
- Quorum calculation
- Availability manager

## Setup

RRP supports various mode of operation:

- Active: both rings will be active and in use
- Passive: only one of the N ring is in use, the second one will be used only if the first one fails

Doing this on a running cluster is totally possible. First put your cluster on maintenance mode, this mode means that Pacemaker won't orchestrate your cluster and will put your resource as `unmanaged`. It allows you to perform some critical operations like upgrading Corosync. The resources are still running but unmanaged by Pacemaker.

```bash
$ sudo crm configure property maintenance-mode=true
```

The state of your cluster must change with an `unmanaged` flag between parenthesis:

```bash
$ crm_mon -1
Stack: corosync
Current DC: vanna (version 1.1.17-1.el6-b36b869) - partition with quorum
Last updated: Fri Jun  8 09:20:27 2018
Last change: Fri Jun  8 09:17:38 2018 by root via cibadmin on victor

2 nodes configured
11 resources configured

              *** Resource management is DISABLED ***
  The cluster will not attempt to start, stop or recover services

Online: [ vanna victor ]

Active resources:

 Resource Group: g_Master
     p_lsyncd   (lsb:lsyncd):   Started victor (unmanaged)
     p_nfsserver        (ocf::heartbeat:nfsserver):     Started victor (unmanaged)
     p_tomcat   (ocf::heartbeat:tomcat):        Started victor (unmanaged)
     p_httpd    (ocf::heartbeat:apache):        Started victor (unmanaged)
     p_dhcpd    (ocf::heartbeat:dhcpd): Started victor (unmanaged)
     p_vip_hms  (ocf::heartbeat:IPaddr2):       Started victor (unmanaged)
     p_vip_kitting      (ocf::heartbeat:IPaddr2):       Started victor (unmanaged)
 Master/Slave Set: ms_mysql [p_mysql] (unmanaged)
     p_mysql    (ocf::heartbeat:mysql): Master victor (unmanaged)
     p_mysql    (ocf::heartbeat:mysql): Slave vanna (unmanaged)
 Clone Set: cln_ping [p_ping] (unmanaged)
     p_ping     (ocf::pacemaker:ping):  Started victor (unmanaged)
     p_ping     (ocf::pacemaker:ping):  Started vanna (unmanaged)
```

Before adding second ring you can see that there's only one ring there:

```bash
$ sudo corosync-cfgtool -s
Printing ring status.
Local node ID 1
RING ID 0
        id      = 10.0.1.98
        status  = ring 0 active with no faults
```

Edit `corosync.conf` with the following:

```bash
totem {
    version: 2
    secauth: on
    threads: 0
    rrp_mode: passive
    interface {
        ringnumber: 0
        bindnetaddr: 10.0.1.0
        mcastaddr: 226.94.1.1
        mcastport: 5405
        ttl: 1
        }
    interface {
        ringnumber: 1
        bindnetaddr: 10.0.2.0
        mcastaddr: 226.94.1.2
        mcastport: 5407
        ttl: 1
    }
}
```

To be simple, you just have to:

- Enable RRP mode with the `rrp_mode: passive` option
- Add a new interface sub-section with:
    - A new ring number
    - The address of your network
    - A new multicast address
    - A new multicast port

Corosync uses two UDP ports **mcastport (for mcast receives)** and **mcastport -1 (for mcast sends**. By default Corosync uses the mcastport 5405 consequently it will bind to:

- mcast receives: 5405
- mcast sends: 5404

In a redundant ring setup you need to specify a gap here setting 5407 will do the following:

- mcast receives: 5407
- mcast sends: 5406

Restart the Corosync daemon on each nodes and check the result:

```bash
$ sudo corosync-cfgtool -s
Printing ring status.
Local node ID 1
RING ID 0
        id      = 10.0.1.98
        status  = ring 0 active with no faults
RING ID 1
        id      = 10.0.2.98
        status  = ring 1 active with no faults
```

Check the totem members:

```bash
$ sudo corosync-cmapctl | grep member
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(10.0.1.98) r(1) ip(10.0.2.98)
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(10.0.1.99) r(1) ip(10.0.2.99)
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 2
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
```

One more validation using the member's ID:

```bash
$ sudo corosync-cfgtool -a 1 -a 2
10.0.1.98 10.0.2.98
10.0.1.99 10.0.2.99
```

Finally disable the maintenance mode:

```bash
$ sudo crm configure property maintenance-mode=false
```

## Testing

After setting up RRP the most important thing to do is to test whether it works or not. The easiest way to test the RRP mode is to shutdown one of the interfaces:

```bash
$ sudo ifdown eth2
$ sudo corosync-cfgtool -s
Printing ring status.
Local node ID 1
RING ID 0
        id      = 10.0.1.98
        status  = ring 0 active with no faults
RING ID 1
        id      = 10.0.2.98
        status  = Marking ringid 1 interface 10.0.2.98 FAULTY
```

And you will find out the cluster is still running without outage.

## Conclusion

To put HA on your application in production environment, enabling RRP with bonded NIC is mandatory! This will make your application 'highly highly' available.

## References

- [Corosync: Redundant Ring Protocol](https://www.sebastien-han.fr/blog/2012/08/01/corosync-rrp-configuration/)
