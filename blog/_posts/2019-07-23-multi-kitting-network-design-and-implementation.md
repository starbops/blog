---
layout: post
title: 'Multi-kitting Network Design and Implementation'
category: note
slug: multi-kitting-network-design-and-implementation
---
As KDDI/NOS' requests, we're constructing a new network architecture of our
development site which consists of three parts:

-  KCPS Bare-Metal: for CKKB (HaaS-like project)
-  KCPS: for original KCPS
-  Dev: internal use of BAMPI team

![itri-kcps-development-environment.png](/assets/images/multi-kitting-network-design-and-implementation/itri-kcps-development-environment.png)

To make the new network architecture work, the main challenges are:

-  VLAN
-  Routing
-  DHCP relay
-  ACL

Currently, Cisco N3K is our core router (actually it is a layer 3 switch), it
maintains several static routes, so everyone can send packets to one another. By
adopting the new network architecture, we cannot connect to most of our servers
inside server room from the office. There must be one or two bastion hosts for
us without deploying a VPN. These bastion hosts must at least reside in VLAN 5
and VLAN 168.

Now the new network is working, the next step is to setup DHCP relay. BAMPI
needs to hear DHCP discover packets which are broadcast-based. Setting DHCP
helper address per VLAN interface will do the job. This one is surprisingly
without any trouble happened.

Finally it's ACL. According to our customer's requests, some subnets cannot
communicate with other subnets. But at default almost all subnets can
communicate with each other due to connected routes and static routes on Cisco
N3K. To avoid this we need to setup several ACLs. This is still a TODO.
