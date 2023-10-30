---
title: OpenStack Neutron Configuration for HaaS
category: memo
slug: openstack-neutron-configuration-for-haas
date: 2019-07-23
---
HaaS is a emerging type of cloud service model which aims physical machines
rather than virtual machines. Due to this key differences, in a typical HaaS
deployment, network configuration should be VLAN-oriented. HaaS utilizes
Peregrine and OpenStack Neutron to achieve tenant network isolation, DHCP and
layer 3 routing functionalities. To configure Neutron to support HaaS, we need
to modify Neutron ML2 driver's settings `/etc/neutron/plugins/ml2/ml2_conf.ini`:

```text
[ml2]
type_drivers = local,flat,vlan,gre,vxlan

tenant_network_types = vlan,vxlan

mechanism_drivers = openvswitch

[ml2_type_flat]
flat_networks = external

[ml2_type_vlan]
network_vlan_ranges = provider:101:200

[ml2_type_gre]

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True

enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
[ovs]
bridge_mappings = external:br-ex,provider:br-vlan
```

First of all, `vlan` must be filled in `type_drivers` and `tenant_network_types`
in order to support VLAN type provider network. And we defined two provider
networks: "external" and "provider" which map to `br-ex` and `br-vlan`
respectively. The former one is flat type and the latter one is VLAN type.
"external" provider network is for external access, obviously. "provider"
provider network is for tenant networks creation, one VLAN for one tenant
network. All physical machines' network traffic will go through this. In the
configuration file, there's `network_vlan_ranges` setting which specified what
range of VLANs are used for this VLAN type provider network.
