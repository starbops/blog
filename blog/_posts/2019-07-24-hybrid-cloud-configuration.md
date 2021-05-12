---
layout: post
title: 'Hybrid Cloud Configuration'
category: note
slug: hybrid-cloud-configuration
---
## Availability Zone

This article only talks about OpenStack data plane availability, control plane availability is out of the scope.

Think availability zone as a logical subdivision of resources into failure domain, allowing cloud applications to intelligently deploy in ways to maximize their availability.

One of the things that complicates use of availability zones is that each OpenStack project impolements them in their own way (if at all).

- Nova
- Cinder
- Neutron

Think of availability zones in terms of:

- Unplanned failures
- Planned maintenance
- Tenant application design/support

### Nova Availability Zone

Nova tied their availability zone implementation to host aggregates. All availability zones in Nova are host aggregates (though not all host aggregates are availability zones).

```bash
$ nova availability-zone-list
+-----------------------+----------------------------------------+
| Name                  | Status                                 |
+-----------------------+----------------------------------------+
| internal              | available                              |
| |- controller         |                                        |
| | |- nova-conductor   | enabled :-) 2019-01-21T05:52:21.000000 |
| | |- nova-consoleauth | enabled :-) 2019-01-21T05:52:21.000000 |
| | |- nova-scheduler   | enabled :-) 2019-01-21T05:52:22.000000 |
| nova                  | available                              |
| |- compute1           |                                        |
| | |- nova-compute     | enabled :-) 2019-01-21T05:52:17.000000 |
| |- compute2           |                                        |
| | |- nova-compute     | enabled :-) 2019-01-21T05:52:19.000000 |
| |- compute3           |                                        |
| | |- nova-compute     | enabled :-) 2019-01-21T05:52:18.000000 |
+-----------------------+----------------------------------------+
```

## Host Aggregates

One common use case for host aggregates is when you want to support scheduling instances to a subset of compute hosts because they have a specific capability.

To configure the scheduler to support host aggregates, the `scheduler_default_filters` configuration option must contain the `AggregateInstanceExtraSpecsFilter` in addition to the other filters used by the scheduler. Add the following line to `/etc/nova/nova.conf` on the host that runs the `nova-scheduler` service to enable host aggregates filtering, as well as the other filters that are typically enabled:

```
scheduler_default_filters=AggregateInstanceExtraSpecsFilter,RetryFilter,AvailabilityZoneFilter,RamFilter,DiskFilter,ComputeFilter,ComputeCapabilitiesFilter,ImagePropertiesFilter,ServerGroupAntiAffinityFilter,ServerGroupAffinityFilter
```

Then restarts `nova-scheduler` service to apply the new config.

## The Work

For a hybrid virtual and baremetal environment, you have to setup host aggregates for virtual and baremetal hosts. Here we will use a property called `baremetal` to link flavors to host aggregates.

- compute1: libvirt.LibvirtDriver
- compute2: bampi.BampiDriver
- compute3: ironic.IronicDriver

First, we create an aggregate and specify that this aggregate only hosts baremetal instances by giving it an key-value pair. Use admin credential to do the following:

```bash
$ nova aggregate-create baremetal-agg nova
+----+---------------+-------------------+-------+--------------------------+
| Id | Name          | Availability Zone | Hosts | Metadata                 |
+----+---------------+-------------------+-------+--------------------------+
| 1  | baremetal-agg | nova              |       | 'availability_zone=nova' |
+----+---------------+-------------------+-------+--------------------------+
$ nova aggregate-set-metadata 1 baremetal=true
Metadata has been successfully updated for aggregate 1.
+----+---------------+-------------------+-------+--------------------------------------------+
| Id | Name          | Availability Zone | Hosts | Metadata                                   |
+----+---------------+-------------------+-------+--------------------------------------------+
| 1  | baremetal-agg | nova              |       | 'availability_zone=nova', 'baremetal=true' |
+----+---------------+-------------------+-------+--------------------------------------------+
$ nova aggregate-add-host 1 compute2
Host compute2 has been successfully added for aggregate 1
+----+---------------+-------------------+------------+--------------------------------------------+
| Id | Name          | Availability Zone | Hosts      | Metadata                                   |
+----+---------------+-------------------+------------+--------------------------------------------+
| 1  | baremetal-agg | nova              | 'compute2' | 'availability_zone=nova', 'baremetal=true' |
+----+---------------+-------------------+------------+--------------------------------------------+
```

Specify one or more key-value pairs that match the key-value pairs on the host aggregates with scope `aggregate_instance_extra_specs`.

```bash
$ nova flavor-key baremetal set aggregate_instance_extra_specs:baremetal=true
$ nova flavor-show baremetal
+----------------------------+------------------------------------------------------+
| Property                   | Value                                                |
+----------------------------+------------------------------------------------------+
| OS-FLV-DISABLED:disabled   | False                                                |
| OS-FLV-EXT-DATA:ephemeral  | 0                                                    |
| disk                       | 0                                                    |
| extra_specs                | {"aggregate_instance_extra_specs:baremetal": "true"} |
| id                         | 101                                                  |
| name                       | baremetal                                            |
| os-flavor-access:is_public | True                                                 |
| ram                        | 64                                                   |
| rxtx_factor                | 1.0                                                  |
| swap                       |                                                      |
| vcpus                      | 1                                                    |
+----------------------------+------------------------------------------------------+
```

The same process applies on the other aggregate:

```bash
$ nova aggregate-create virtual-agg nova
+----+-------------+-------------------+-------+--------------------------+
| Id | Name        | Availability Zone | Hosts | Metadata                 |
+----+-------------+-------------------+-------+--------------------------+
| 2  | virtual-agg | nova              |       | 'availability_zone=nova' |
+----+-------------+-------------------+-------+--------------------------+
$ nova aggregate-set-metadata 2 baremetal=false
Metadata has been successfully updated for aggregate 2.
+----+-------------+-------------------+-------+---------------------------------------------+
| Id | Name        | Availability Zone | Hosts | Metadata                                    |
+----+-------------+-------------------+-------+---------------------------------------------+
| 2  | virtual-agg | nova              |       | 'availability_zone=nova', 'baremetal=false' |
+----+-------------+-------------------+-------+---------------------------------------------+
$ nova aggregate-add-host virtual-agg compute1
Host compute1 has been successfully added for aggregate 2
+----+-------------+-------------------+------------+---------------------------------------------+
| Id | Name        | Availability Zone | Hosts      | Metadata                                    |
+----+-------------+-------------------+------------+---------------------------------------------+
| 2  | virtual-agg | nova              | 'compute1' | 'availability_zone=nova', 'baremetal=false' |
+----+-------------+-------------------+------------+---------------------------------------------+
```

Specify key-value pair that matches the one set on corresponding aggregate:

```bash
$ nova flavor-key m1.nano set aggregate_instance_extra_specs:baremetal=false
$ nova flavor-show m1.nano
+----------------------------+-------------------------------------------------------+
| Property                   | Value                                                 |
+----------------------------+-------------------------------------------------------+
| OS-FLV-DISABLED:disabled   | False                                                 |
| OS-FLV-EXT-DATA:ephemeral  | 0                                                     |
| disk                       | 1                                                     |
| extra_specs                | {"aggregate_instance_extra_specs:baremetal": "false"} |
| id                         | 0                                                     |
| name                       | m1.nano                                               |
| os-flavor-access:is_public | True                                                  |
| ram                        | 64                                                    |
| rxtx_factor                | 1.0                                                   |
| swap                       |                                                       |
| vcpus                      | 1                                                     |
+----------------------------+-------------------------------------------------------+
```

## Appendix

Ironic cannot co-exist with Libvirt in one single site. After Newton version there is a new mechanism to enhance the old flavors which is called "resource classes". This will unify the scheduling mechanism between virtual machines and baremetal machines.

![OpenStack Host Aggregates](/assets/images/hybrid-cloud-configuration/shp-host-aggs.png)

## References

- [The first and final words on OpenStack availability zones](https://www.mirantis.com/blog/the-first-and-final-word-on-openstack-availability-zones/)
- [OpenStack Docs: Compute schedulers](https://docs.openstack.org/newton/config-reference/compute/schedulers.html)
