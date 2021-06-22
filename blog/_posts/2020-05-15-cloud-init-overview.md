---
layout: post
title: 'Cloud-Init Overview'
category: note
slug: cloud-init-overview
---
Cloud-init's behavior can be configured via user-data. User-data can be given by
the user at instance launch time.

## Boot Stages

1. Generator
1. Local
1. Network
1. Config
1. Final

### Generator

When booting under systemd, a generator will run that determines if
cloud-init.target should be included in the boot goals. By default, this
generator will enable cloud-init.

### Local

The purpose of the local stage is:

-  Locate "local" data sources
-  Apply networking configuration to the system (including "Fallback")

This stage must block network bring-up or any stale configuration might already
have been applied. That could have negative effects such as DHCP hooks or
broadcast of an old hostname. It would also put the system in an odd state to
recover from as it may then have to restart network devices.

### Network

-  systemd service: `cloud-init.service`
-  modules: `cloud_init_modules` in `/etc/cloud/cloud.cfg`

This stage requires all configured networking to be online, as it will fully
process any user-data that is found. This stage runs the `disk_setup` and
`mounts` modules which may partition and format disks and configure mount points
(such as in /etc/fstab). Those modules cannot run earlier as they may receive
configuration input from sources only available via network. For example, a user
may have provided user-data in a network resource that describes how local
mounts should be done.

### Config

-  systemd service: `cloud-config.service`
-  modules: `cloud_config_modules` in `/etc/cloud/cloud.cfg`

This stage runs config modules only. Modules that do not really have an effect
on other stages of boot are run here.

### Final

-  systemd service: `cloud-final.service`
-  modules: `cloud_final_modules` in `/etc/cloud/cloud.cfg`

This stage runs as late in boot as possible. Any scripts that a user is
accustomed to running after logging into a system should run correctly here.

## Fallback Network Configuration

Cloud-init will attempt to determine which of any attached network devices is
most likely to have a connection and then generate a network configuration to
issue a DHCP request on that interface.

Cloud-init

# Metadata

Nova presents configuration information to instances it starts via a mechanism
called metadata. These mechanisms are widely used via helpers such as cloud-init
to specify things like the root password the instance should use.

This metadata is made available via either a config driver or the metadata
service and can be somewhat customized by the user using the user data feature.

## Metadata Service

Metadata service lets an instance retrieve instance specific information, e.g.
hostname, IP, routes, SSH keys, user-data, vendor-data and various default
settings even commands and shell scripts. All of these are generally handled by
a service in the instance like cloud-init.

### Supported Versions

```bash
[starbops@shitcoin ~]$ curl http://169.254.169.254/openstack
2012-08-10
2013-04-04
2013-10-17
2015-10-15
2016-06-30
2016-10-06
latest
```

### Endpoints of Metadata Service

List all meta-data service's endpoints by requesting
`http://169.254.169.254/latest/meta-data`

```bash
[starbops@shitcoin ~]$ curl http://169.254.169.254/latest/meta-data
ami-id
ami-launch-index
ami-manifest-path
block-device-mapping/
hostname
instance-action
instance-id
instance-type
local-hostname
local-ipv4
placement/
public-hostname
public-ipv4
reservation-id
security-groups
```

For example, getting floating IP address bond with the instance:

```bash
[starbops@shitcoin ~]$ curl http://169.254.169.254/latest/meta-data/public-ipv4
100.74.37.104
```

To see what user-data have been filled:

```bash
[starbops@shitcoin ~]$ curl http://169.254.169.254/latest/user-data
#cloud-config

#packages:
#  - htop

#ssh_authorized_keys:
#  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkgolYx6IoPSYnhZMdGivUJOm4AMtI0gkjFkY/53V4idbliQHAMJHGdMGYdlEm5ThOCw3DDblsQDNy7EZJaa9+T1imwrnUg0fYU13u+Tfq7Fg+TIn4hf4uG/ei2r1MLp2/lO/6dEPUGv2TiBQ+SVfB8yt2IUVIGgqNhGWJi/p5uw9O5KiAPN1UmT3CvpWYVFnfqvnDwnOMJkXg9xN8AbTkAHS1YDIljNMwBisaOvI5cjgZ5a+ovp2pdHBxZWyPAb7Y5NvlQHGtJQIlbWTcxIBu8/1YPbZlkTcgB0ghDf0upgKunqFHh/Zq3sdEEUyQ2Xr6qdVyaXwNQJhV8Kge196r ubuntu@controller

users:
  - default
  - name: starbops
    gecos: Zespre Schmidt
    sudo: ALL=(ALL) NOPASSWD:ALL
    #lock_passwd: false
    #passwd: $6$rounds=4096$lDq1KTfs/T/e7$EfyJlD0aqyO7W8oSOumQySoYxfqBC5OxzGXnGrFV6AIMms5QnE0pwdwJttTw2iliFKoKfnFnGLfgauLVF2yoa1
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkgolYx6IoPSYnhZMdGivUJOm4AMtI0gkjFkY/53V4idbliQHAMJHGdMGYdlEm5ThOCw3DDblsQDNy7EZJaa9+T1imwrnUg0fYU13u+Tfq7Fg+TIn4hf4uG/ei2r1MLp2/lO/6dEPUGv2TiBQ+SVfB8yt2IUVIGgqNhGWJi/p5uw9O5KiAPN1UmT3CvpWYVFnfqvnDwnOMJkXg9xN8AbTkAHS1YDIljNMwBisaOvI5cjgZ5a+ovp2pdHBxZWyPAb7Y5NvlQHGtJQIlbWTcxIBu8/1YPbZlkTcgB0ghDf0upgKunqFHh/Zq3sdEEUyQ2Xr6qdVyaXwNQJhV8Kge196r ubuntu@controller

#ssh_pwauth: true

#runcmd:
#  - sed -i -e '$aAllowUsers starbops' /etc/ssh/sshd_config
#  - systemctl restart ssh.service
hostname: shitcoin
```

### How It Works

```text
instance --> neutron-ns-metadata-proxy --> neutron-metadata-agent --> nova-api
```

#### Instance

Instance makes request to `http://169.254.169.254`. Because the destination does
hit any rules in the routing table of the instance, it just falls back to the
default route. The request follows the default route to router namespace. Here
is the `iptables` rule for this situation:

```text
REDIRECT  tcp  --  0.0.0.0/0      169.254.169.254  tcp dpt:80 redir ports 9697
```

The request being redirected is still inside the same router namespace.

#### neutron-ns-metadata-proxy

`neutron-ns-metadata-proxy` is running and listening on TCP 9697 port in each
router namespaces. While processed by `neutron-ns-metadata-proxy`, following
headers are added to the request:

```text
X-forwarded-for: <Instance IP>
X-neutron-router-id: <Router UUID>
```

And the request is forwarded through UNIX socket to `neutron-metadata-agent`.

#### neutron-metadata-agent

`neutron-metadata-agent` listens on the socket `/var/lib/neutron/metadata_proxy`
and communicates with public OpenStack APIs for more information. More headers
are added:

```bash
X-Instance-ID: <Instance UUID>
X-Tenant-ID: <Tenant UUID>
X-Instance-ID-Signature: <HMAC secret, instance_id>
```

#### nova-api

## References

-  [2.9. Configuring instances at boot time](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/4/html/End_User_Guide/user-data.html)
-  [Network Configuration - Cloud-Init 18.4 documentation](https://cloudinit.readthedocs.io/en/latest/topics/network-config.html)
-  [OpenStack Docs: Metadata](https://docs.openstack.org/nova/latest/user/metadata.html)
