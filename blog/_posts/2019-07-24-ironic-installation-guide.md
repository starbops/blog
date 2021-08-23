---
layout: post
title: 'Ironic Installation Guide'
category: memo
slug: ironic-installation-guide
---
OpenStack version: Newton

## Ironic API

In this installation guide, Ironic API will be installed on controller node.

### Prerequisites

Create essential user, service, and endpoint information for Ironic with
OpenStack admin credential.

```bash
openstack user create --password password --email ironic@example.com ironic
openstack role add --project service --user ironic admin
openstack service create --name ironic --description "Ironic baremetal provisioning service" baremetal
openstack endpoint create --region RegionOne baremetal admin http://controller:6385
openstack endpoint create --region RegionOne baremetal public http://controller:6385
openstack endpoint create --region RegionOne baremetal internal http://controller:6385
```

```bash
openstack role create baremetal_admin
openstack role create baremetal_observer
openstack project create baremetal
openstack user create --domain default --project-domain default --project baremetal --password password baremetal_demo
openstack role add --user-domain default --project-domain default --project baremetal --user baremetal_demo baremetal_observer
```

### Installation

```bash
sudo apt install ironic-api
```

### Configuration

In `/etc/ironic/ironic.conf`:

```text
[DEFAULT]
auth_strategy=keystone
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron
debug = true
log_dir=/var/log/ironic
transport_url = rabbit://openstack:password@controller

[agent]

[amt]

[api]

[audit]

[cimc]

[cisco_ucs]

[conductor]

[console]

[cors]

[cors.subdomain]

[database]
connection=mysql+pymysql://ironic:password@controller/ironic?charset=utf8

[deploy]

[dhcp]

[disk_partitioner]

[disk_utils]

[drac]

[glance]

[iboot]

[ilo]

[inspector]

[ipmi]

[irmc]

[ironic_lib]

[iscsi]

[keystone]

[keystone_authtoken]
auth_type=password
auth_uri=http://controller:5000
auth_url=http://controller:35357
project_domain_name=Default
user_domain_name=Default
project_name=service
username=ironic
password=password

[matchmaker_redis]

[metrics]

[metrics_statsd]

[neutron]

[oneview]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

[oslo_messaging_zmq]

[oslo_policy]

[pxe]

[seamicro]

[service_catalog]

[snmp]

[ssh]

[ssl]

[swift]

[virtualbox]
```

In `/etc/nova/nova.conf`:

```text
...
scheduler_host_manager=ironic_host_manager
ram_allocation_ratio=1.0
reserved_host_memory_mb=0
scheduler_use_baremetal_filters=True
scheduler_tracks_instance_changes=False
scheduler_host_subset_size=9999999

firewall_driver = nova.virt.firewall.NoopFirewallDriver
...
```

### Prepare Provisioning/Cleaning Network

On controller node, we need two additional NICs for this feature to work. Both
NICs must connect to the same L2 network as our baremetal nodes reside. One for
making Linux bridge under Neutron's control (ens21), the other for Ironic API
access endpoint in baremetal network (ens22).

In `/etc/neutron/plugins/ml2/ml2_conf.ini`:

```text
[ml2_type_flat]
flat_networks = external,flat
```

In `/etc/neutron/plugins/ml2/linuxbridge_agent.ini`:

```text
[linux_bridge]
physical_interface_mappings = external:ens19,vlan:ens20,flat:ens21
```

Restart related Neutron services.

```bash
sudo systemctl restart neutron-linuxbridge-agent.service
sudo systemctl restart neutron-server.service
```

Create Neutron network for baremetal provisioning/cleaning purposes which is in
flat type.

```bash
neutron net-create baremetal-net --shared --provider:network_type flat --provider:physical_network flat
neutron subnet-create baremetal-net 100.74.41.0/24 --name baremetal-subnet --ip-version=4 --gateway=100.74.41.254 --allocation-pool start=100.74.41.200,end=100.74.41.250 --enable-dhcp
```

Set up the other NIC for later baremetal nodes API accessing.

```bash
sudo ip addr add 100.74.41.200/24 dev ens22
sudo ip link set up dev ens22
```

Edit `/etc/network/interfaces` to make the network configuration persistent.

## Ironic Conductor

In this installation guide, there is a dedicate node for Ironic conductor.

### Installation

```bash
sudo apt install ironic-conductor
```

### Configuration

In `/etc/ironic/ironic.conf`:

```text
[DEFAULT]
auth_strategy = keystone
enabled_drivers = pxe_ipmitool
enabled_network_interfaces = noop,flat,neutron
default_network_interface = neutron
my_ip=100.74.41.124
log_dir=/var/log/ironic
transport_url = rabbit://openstack:password@controller

[agent]

[amt]

[api]

[audit]

[cimc]

[cisco_ucs]

[conductor]
api_url=http://100.74.41.200:6385

[console]

[cors]

[cors.subdomain]

[database]
connection=mysql+pymysql://ironic:password@controller/ironic?charset=utf8

[deploy]

erase_devices_priority = 0

[dhcp]

[disk_partitioner]

[disk_utils]

[drac]

[glance]
glance_host=controller

[iboot]

[ilo]

[inspector]
enabled = True
service_url = http://ironic:5050

[ipmi]

[irmc]

[ironic_lib]

[iscsi]

[keystone]

[keystone_authtoken]
auth_type=password
auth_url=http://controller:5000
username=ironic
password=password
project_name=service
project_domain_name=Default
user_domain_name=Default

[matchmaker_redis]

[metrics]

[metrics_statsd]

[neutron]
cleaning_network_uuid = 28791788-59d7-4346-89aa-6f895b523c0c
provisioning_network_uuid = 28791788-59d7-4346-89aa-6f895b523c0c

[oneview]

[oslo_concurrency]

[oslo_messaging_amqp]

[oslo_messaging_notifications]

[oslo_messaging_rabbit]

rabbit_host=controller

[oslo_messaging_zmq]

[oslo_policy]

[pxe]
pxe_append_params = coreos.autologin sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkgolYx6IoPSYnhZMdGivUJOm4AMtI0gkjFkY/53V4idbliQHAMJHGdMGYdlEm5ThOCw3DDblsQDNy7EZJaa9+T1imwrnUg0fYU13u+Tfq7Fg+TIn4hf4uG/ei2r1MLp2/lO/6dEPUGv2TiBQ+SVfB8yt2IUVIGgqNhGWJi/p5uw9O5KiAPN1UmT3CvpWYVFnfqvnDwnOMJkXg9xN8AbTkAHS1YDIljNMwBisaOvI5cjgZ5a+ovp2pdHBxZWyPAb7Y5NvlQHGtJQIlbWTcxIBu8/1YPbZlkTcgB0ghDf0upgKunqFHh/Zq3sdEEUyQ2Xr6qdVyaXwNQJhV8Kge196r ubuntu@controller" ipa-debug=1

[seamicro]

[service_catalog]

[snmp]

[ssh]

[ssl]

[swift]

[virtualbox]
```

To accelerate cleaning process, disable disk erasure in default cleaning steps.
Cleaning ATA disks which do not support cryptographic secure erase could be
extremely time consuming. In `/etc/ironic/ironic.conf`:

```text
[deploy]
erase_devices_priority=0
```

### Setting Provisioning/Cleaning Network

Of course you can specify different networks for provisioning and cleaning, but
in our case we'll use the same network created above. Update the following
configuration in `/etc/ironic/ironic.conf`:

```text
[neutron]
cleaning_network_uuid = 28791788-59d7-4346-89aa-6f895b523c0c
provisioning_network_uuid = 28791788-59d7-4346-89aa-6f895b523c0c
```

Restart Ironic conductor service.

```bash
sudo systemctl restart ironic-conductor.service
```

## Ironic Python Agent (IPA)

In this guide we'll build CoreOS version IPA image. So a Docker-ready
environment is essential. There's another way to build IPA images, please refer
to [Diskimage-builder](https://docs.openstack.org/diskimage-builder/latest/).

### Prerequisites

We're building IPA image in CentOS 6.9 environment just because in our
environment it has Docker client installed and there is a well-configured 3-node
Docker Swarm for the use. But the default Python interpreter came along with the
OS is relatively outdated:

```bash
# python -V
Python 2.6.6
```

Upgrading Python without touching the one system uses could be simple. Download
the source tarball and start compiling:

```bash
# yum install gcc findutils grep gpg util-linux
# wget https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tgz
# tar -zxf Python-2.7.10.tgz
# cd Python-2.7.10/
# ./configure
# make altinstall
# ln -s /usr/local/bin/python2.7 /usr/local/bin/python
# python -V
Python 2.7.10
```

### Image Building

```bash
git clone https://git.openstack.org/openstack/ironic-python-agent.git
cd ironic-python-agent/
git checkout tags/newton-eol -b newton-eol
cd imagebuild/coreos/
make
```

### Gaining Access to IPA on a Node

Here we'll use CoreOS for illustration.

Add `sshkey="ssh-rsa AAAA..."` to `pxe_append_params` setting in `ironic.conf`
file then restart Ironic conductor service. After that you're able to `ssh
core@<ip-address-of-node>`.

On the other hand, if you want to access IPA via console, just simply add
`coreos.autologin` to `pxe_append_params` setting in `ironic.conf then restart
Ironic conductor service.

### Set IPA to debug logging

Add `ipa-debug=1` to `pxe_append_params` setting in `ironic.conf` file then
restart Ironic conductor service. IPA logs could be found with:

```bash
sudo journalctl -u ironic-python-agent.service
```

## Network Generic Switch

In order to fully enable multi-tenancy feature provided by Ironic, one key point
is Neutron support. Neutron supports multi-tenancy by nature. It creates overlay
networks through various network technologies on top of provider networks. But
right now baremetal multi-tenancy could only be done through VLAN segregation.
And the most important, Neutron must have control over physical switches which
connect the baremetal nodes. So the "Network Generic Switch" mechanism driver
comes to help!

### Source Modification

Just before the installation, we have to modify the source code for it to work
as expected.

```bash
git clone https://github.com/openstack/networking-generic-switch.git
cd networking-generic-switch/
git checkout tags/newton-eol -b newton-eol
```

In `networking_generic_switch/generic_switch_mech.py`, there are two places to
modify. Change the default VLAN ID 1 to the actual VLAN ID you use in your
deployment. In our case it is VLAN ID 41.

```python
def delete_port_postcommit(self, context):
    ...
            # If segmentation ID is None, set vlan 41
            if not segmentation_id:
                segmentation_id = '41'
                ...
```

```python
def bind_port(self, context):
    ...
            # If segmentation ID is None, set vlan 41
            if not segmentation_id:
                segmentation_id = '41'
                ...
```

If you don't do this, Neutron will not know what VLAN ID is for
provisioning/cleaning network (flat type), and it defaults to VLAN ID 1 which
breaks the provisioning/cleaning actions.

### Installation

```bash
sudo python setup.py install
```

```bash
sudo pip install netmiko==0.5.0
```

### Configuration

`/etc/neutron/plugins/ml2/ml2_conf.ini`:

```text
[ml2]
mechanism_drivers = linuxbridge,genericswitch
```

`/etc/neutron/plugins/ml2/ml2_conf_genericswitch.ini`:

```text
[genericswitch:Catalyst-202]
device_type = netmiko_cisco_ios
username = admin
password = password
secret = password
ip = 100.74.49.202

[genericswitch:Catalyst-203]
device_type = netmiko_cisco_ios
username = admin
password = password
secret = password
ip = 100.74.49.203
```

Restart `neutron-server`.

## Ironic Inspector

### Prerequisites

In order to use Ironic Inspector with OpenStack client, we need to create
service endpoint for it.

```bash
openstack user create --domain default --password-prompt ironic-inspector
openstack role add --project service --user ironic-inspector admin
openstack service create --name ironic-inspector --description "Ironic baremetal discovery service" baremetal-introspection
openstack endpoint create --region RegionOne baremetal-introspection admin http://ironic:5050
openstack endpoint create --region RegionOne baremetal-introspection public http://ironic:5050
openstack endpoint create --region RegionOne baremetal-introspection internal http://ironic:5050
```

### Installation

Install Ironic Inspector and Dnsmasq on Ironic (conductor) node.

```bash
sudo apt install ironic-inspector python-memcache dnsmasq
```

Install Ironic Inspector client package on controller (for `openstack baremetal
introspection` command to work) and conductor (for `openstack baremetal node
inspect` command to work) node.

```bash
sudo apt install python-ironic-inspector-client
```

### Configuration

`/etc/ironic/ironic.conf`

`/etc/ironic-inspector/inspector.conf`:

```text
[DEFAULT]
rootwrap_config = /etc/ironic-inspector/rootwrap.conf

[capabilities]

[cors]

[cors.subdomain]

[database]
connection = mysql+pymysql://ironic_inspector:password@controller/ironic_inspector?charset=utf8

[discoverd]

[discovery]
enroll_node_driver = pxe_ipmitool

[firewall]
dnsmasq_interface = ens19

[ironic]
auth_url = http://controller:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
region_name = RegionOne
project_name = service
username = ironic
password = password

[keystone_authtoken]
memcached_servers = controller:11211
auth_uri = http://controller:5000
auth_url = http://controller:35357
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = ironic-inspector
password = password

[pci_devices]

[processing]
add_ports = all
keep_ports = present
processing_hooks = $default_processing_hooks,local_link_connection
ramdisk_logs_dir = /var/log/ironic-inspector/ramdisk
node_not_found_hook = enroll

[swift]
```

Add the following line in `/etc/default/dnsmasq` to prevent Dnsmasq overwriting
the original nameserver in `/etc/resolv.conf`, otherwise it will break your
Internet name resolution.

```text
DNSMASQ_EXCEPT=lo
```

`/etc/dnsmasq.conf`:

```text
port=0
interface=ens19
bind-interfaces
dhcp-range=100.74.41.151,100.74.41.200
enable-tftp
tftp-root=/tftpboot
dhcp-boot=pxelinux.0
```

`/tftpboot/pxelinux.cfg/default`:

```text
default introspect

label introspect
kernel /tftpboot/images/coreos_production_pxe.vmlinuz
append initrd=/tftpboot/images/coreos_production_pxe_image-oem.cpio.gz selinux=0 disk= ipa-inspection-callback-url=http://100.74.41.124:5050/v1/continue ipa-inspection-collectors=default,logs ipa-collect-lldp=1 ironic_api_url= troubleshoot=0 text coreos.autologin boot_option=  ipa-api-url=http://100.74.41.200:6385 ipa-driver-name=pxe_ipmitool boot_mode= coreos.configdrive=0 ipa-debug=1
ipappend 3
```

Prepare IPA ramdisk under `/tftpboot/images` directory for PXE booting.

```bash
sudo systemctl restart ironic-conductor.service
sudo systemctl restart dnsmasq.service
sudo -u ironic-inspector ironic-inspector --config-file /etc/ironic-inspector/inspector.conf
```

# Ironic Operation Guide

## Flavor Creation

```bash
CPU=2
RAM_MB=1024
DISK_GB=100
ARCH=x86_64
nova flavor-create my-baremetal-flavor auto $RAM_MB $DISK_GB $CPU
nova flavor-key my-baremetal-flavor set cpu_arch=$ARCH
nova flavor-key my-baremetal-flavor set capabilities:boot_option="local"
```

## Image Preparation

Upload deploy images:

```bash
glance image-create --name deploy-coreos-vmlinuz --visibility public --disk-format aki --container-format aki < coreos_production_pxe.vmlinuz
glance image-create --name deploy-coreos-initrd --visibility public --disk-format ari --container-format ari < coreos_production_pxe_image-oem.cpio.gz
```

Upload user images:

```bash
glance image-create --name my-kernel --visibility public --disk-format aki --container-format aki < my-image.vmlinuz
MY_VMLINUZ_UUID="b332e81d-bd3d-4c24-8d84-83292514eecc"
glance image-create --name my-image.initrd --visibility public --disk-format ari --container-format ari < my-image.initrd
MY_INITRD_UUID="801c428e-561d-4b32-94d0-125eab9ff75b"
glance image-create --name my-image --visibility public --disk-format qcow2 --container-format bare --property kernel_id=$MY_VMLINUZ_UUID --property ramdisk_id=$MY_INITRD_UUID < my-image.qcow2
```

## Enrolment

### Manual Enrolment

Use OpenStack admin credential.

```bash
export IRONIC_API_VERSION=1.20
export OS_BAREMETAL_API_VERSION=1.20
```

```bash
$ ironic node-create -d pxe_ipmitool -n hp-11
$ ironic node-update hp-11 add \
        driver_info/ipmi_username=Administrator \
        driver_info/ipmi_password=Z6GRK2G8 \
        driver_info/ipmi_address=100.74.41.11 \
        driver_info/ipmi_terminal_port=623
$ ironic node-update hp-11 add \
        driver_info/deploy_kernel=d891d03d-54df-4892-ac35-fb89221f6fd9 \
        driver_info/deploy_ramdisk=d5dc5a93-d07c-4391-afa5-9dd568724e3a
$ ironic node-update hp-11 add \
        properties/cpus=2 \
        properties/memory_mb=32768 \
        properties/local_gb=1024 \
        properties/cpu_arch=x86_64 \
        properties/capabilities="boot_option:local"
$ ironic node-update hp-11 add \
        instance_info/ramdisk=801c428e-561d-4b32-94d0-125eab9ff75b \
        instance_info/kernel=b332e81d-bd3d-4c24-8d84-83292514eecc \
        instance_info/image_source=dfab5186-682e-48d4-9427-7ac07dea3ace \
        instance_info/root_gb=50
$ ironic port-create -n fed2481a-7cc2-459d-b9cd-4c74b722c59a -a 98:f2:b3:3f:f4:6c \
        -l switch_id=00:5f:86:13:db:80 \
        -l switch_info=Catalyst-203 \
        -l port_id=Gi1/0/31 \
        --pxe-enabled true
$ ironic node-validate fed2481a-7cc2-459d-b9cd-4c74b722c59a
+------------+--------+---------------+
| Interface  | Result | Reason        |
+------------+--------+---------------+
| boot       | True   |               |
| console    | True   |               |
| deploy     | True   |               |
| inspect    | None   | not supported |
| management | True   |               |
| network    | True   |               |
| power      | True   |               |
| raid       | True   |               |
+------------+--------+---------------+
```

### Automated Enrolment (Inspect)

Just simply power on the baremetal nodes, Ironic inspector will handle the rest
of it.

For the record, Ironic inspector has not yet supported the use of `port` scheme
in introspection rule by newton version. That is, admin cannot configure extra
information like `local_link_connection` with introspection rule. Ironic
inspector default plugin includes `local_link_connection`

## Manageable

```bash
ironic node-set-provision-state hp-11 manage
```

## Cleaning

### Automated Cleaning

```bash
ironic node-set-provision-state hp-11 provide
```

### Manual Cleaning

```bash
ironic node-set-provision-state hp-11 clean \
      --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
```

## Workload

```bash
nova boot --flavor my-baremetal-flavor --image my-image --nic net-id=070c1b6d-3777-416a-a971-4216dce67b1a --key my-key test-baremetal
```

## Appendix

### Diskimage-Builder

```bash
yum install squashfs-tools
pip install diskimage-builder
DIB_DEV_USER_USERNAME=user DIB_DEV_USER_PASSWORD=password DIB_DEV_USER_PWDLESS_SUDO=yes disk-image-create ironic-agent ubuntu devuser proliant-tools -o ironic-agent
```

## References

-  [Bare Metal service installation guide](https://docs.openstack.org/project-install-guide/baremetal/newton/)
-  [Node Cleaning - Ironic 6.2.5.dev3 documentation](https://docs.openstack.org/ironic/newton/deploy/cleaning.html)
-  [Troubleshooting Ironic-Python-Agent (IPA)](https://docs.openstack.org/ironic-python-agent/latest/admin/troubleshooting.html)
-  [Multitenancy in Bare Metal Service - Ironic 6.2.5.dev3 documentation](https://docs.openstack.org/ironic/newton/deploy/multitenancy.html)
-  [linux - resolv.conf keeps getting overwritten when dnsmasq is restarted,
   breaking dnsmasq - Super
   User](https://superuser.com/questions/894513/resolv-conf-keeps-getting-overwritten-when-dnsmasq-is-restarted-breaking-dnsmas)
