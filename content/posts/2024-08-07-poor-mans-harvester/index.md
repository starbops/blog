---
title: Poor Man's Harvester
category: memo
slug: poor-mans-harvester
date: 2024-08-07
---
## Overview

It's possible to provision machines from scratch to act like running a
[Harvester](https://harvesterhci.io/) cluster but in a poor man's fashion.
Though the functionality is not as rich as what a legitimate Harvester cluster
is capable of, it helps us understand the core technology of an HCI solution in
terms of:

-  Compute: [Kubernetes](https://kubernetes.io/) (the container orchestration
   platform) and [KubeVirt](https://kubevirt.io/) (enabling virtualization on
   top of Kubernetes)
-  Storage: [Local Path
   Provisioner](https://github.com/rancher/local-path-provisioner) (a simple
   dynamic persistent volume provisioner) and [Containerized Data Importer
   (CDI)](https://github.com/kubevirt/containerized-data-importer) (populating
   VM disks using existing images)
-  Networking: [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni)
   (enabling attaching multiple network interfaces to pods)

Note: the resulting cluster does not have the VM live migration ability due to
the non-migratable nature of local volumes. Even if the cluster consists of
multiple nodes, it's still impossible. After all, it's poor man's Harvester -
Parvester.

## Installation

In this post, I'll show you how to provision a poor man's Harvester step by
step. The versions of each component are:

-  Kubernetes: v1.28.11 ([RKE2](https://docs.rke2.io/))
-  KubeVirt: v1.1.1
-  Local Path Provisioner: v0.0.28
-  CDI: v1.59.0
-  Multus CNI: v4.0.2

For simplicity, we'll build a single-node cluster. You can add more nodes to
form a multi-node cluster. But as I mentioned, it's still not as powerful as a
genuine multi-node Harvester cluster.

### Kubernetes

We choose RKE2 as the Kubernetes distribution to deploy. Installing RKE2 is as
simple as installing [K3s](https://k3s.io/) with a one-liner (yeah you need to
get a shell on the nodes where you wish to install RKE2):

```shell
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_VERSION=v1.28.11+rke2r1 sh -
```

For a single-node setup, you can skip straight to the part kicking off the RKE2
server; if you want to add more servers or agents later on, consider adding some
configuration beforehands.

```shell
sudo mkdir -p /etc/rancher/rke2/config.yaml.d/
```

Put the following content in `/etc/rancher/rke2/config.yaml` for every server
nodes:

```yaml
token: supersecret
write-kubeconfig-mode: "0644"
tls-san:
- parvester.192.168.48.73.sslip.io
- 192.168.48.73
```

For additional server nodes (not including the initial server node), please
create a new configuration file `/etc/rancher/rke2/config.yaml.d/10-server.yaml`
with the following content:

```yaml
server: https://parvester.192.168.48.73.sslip.io:9345
```

Enable and start the RKE2 server(s) immediately:

```shell
sudo systemctl enable rke2-server.service --now
```

The resulting kubeconfig file will be placed at `/etc/rancher/rke2/rke2.yaml`.
For your convenience, I suggest setting the following two environment variables
(you can persist them in your shell config files):

```shell
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=$PATH:/var/lib/rancher/rke2/bin
```

### Compute - KubeVirt

Before installing KubeVirt, we'd like to check if our machines can run VMs. If
you're pretty sure your machines are capable, then this step could be skipped.

```shell
sudo apt update
sudo apt install libvirt-clients

# Make sure there's no "FAIL" in the command output
sudo virt-host-validate qemu
```

Install KubeVirt is easy; deploy the KubeVirt Operator and create a KubeVirt
custom resource. The operator will start to deploy all the relevant components
for you:

```shell
# Deploy KubeVirt operator
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-operator.yaml

# Instruct the operator to start deploying KubeVirt components by creating the KubeVirt custom resource
kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/kubevirt-cr.yaml
```

We're only able to run VMs when the KubeVirt CR becomes ready.

Additionally, we'd like to install the client tool for KubeVirt: `virtctl`. It
provides some handy commands against VMs that couldn't be done with regular
Kubernetes APIs.

```shell
curl -sfL https://github.com/kubevirt/kubevirt/releases/download/v1.1.1/virtctl-v1.1.1-linux-amd64 -o /tmp/virtctl
sudo install -o root -g root -m 0755 /tmp/virtctl /usr/local/bin/virtctl
```

### Storage

This section is not about installing any third-party storage solution or CSI
plug-in that handles data volumes for VMs. We'll focus on services that
provision volumes from cloud images for VMs to boot up.

#### Local Path Provisioner

KubeVirt has a subproject called [Containerized Data Importer
(CDI)](https://github.com/kubevirt/containerized-data-importer). But before
that, we need to enable dynamic provisioning for persistent volumes. We choose
to use the [Local Path
Provisioner](https://github.com/rancher/local-path-provisioner) for simplicity.

```shell
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml
```

Now that the cluster should be able to handle PersistentVolumeClaim objects with
the `local-path` StorageClass. Whenever we create a PVC, the Local Path
Provisioner will dynamically provision the PersistentVolume for that PVC with a
`hostPath` type of volume.

You can install Longhorn instead of Local Path Provisioner, but that's not
covered in this post.

#### Containerized Data Importer

The README page of the CDI project clearly explains what it is capable of:

> CDI provides the ability to populate PVCs with VM images or other data upon
> creation. The data can come from different sources: a URL, a container
> registry, another PVC (clone), or an upload from a client.

The installation steps are similar to KubeVirt:

```shell
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.59.0/cdi-operator.yaml
kubectl create -f https://github.com/kubevirt/containerized-data-importer/releases/download/v1.59.0/cdi-cr.yaml
```

Once all the relevant components are ready, we can proceed to the next section.

### Networking - Multus CNI

KubeVirt VMs can leverage the pod network directly to have connectivity among
others and the Internet. It's out of the box and easy to use, but having a
significant drawback: the IP addresses of the VMs drift every time the VMs are
rebooted. It's impossible to have a static IP address bound due to the nature of
a pod network. You can instead create a Service object to expose endpoints for
the VMs, but that's unintuitive in terms of the nature of the VM.

Instead, we'll have secondary networks available for the VMs. This is done by
Multus CNI. Here, we deploy the thin plug-in:

```shell
kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/v4.0.2/deployments/multus-daemonset.yml
```

Later, we'll create NetworkAttachmentDefinition objects to set up networks for
VMs to attach to.

## Create a VM

Now that we have all the major components set up, it's time to fire up some VMs!

### Prepare Networks

We need to create a NetworkAttachmentDefinition for the to-be-created VM to
attach. But before that, we have to create a Linux bridge manually for the
NetworkAttachmentDefinition to associate with:

```shell
sudo ip link add br0 type bridge
```

It's essential to create the bridge on each node if you have a multi-node
cluster. The NetworkAttachmentDefinition object is a cluster-wide configuration.
Now it's time to create it:

```shell
cat <<EOF | kubectl apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: net-101
spec:
  config: '{
      "cniVersion": "0.3.1",
      "type": "bridge",
      "bridge": "br0",
      "ipam": {}
    }'
EOF
```

At this point, you'll have a usable NetworkAttachmentDefinition for VMs to
attach to. But we need more than that because we want our VMs to be able to
access the Internet. Without an uplink, VMs connected to the network are just
like starving people on an island. It's okay to have only one network interface
on a node. We can add the interface to the bridge and move the IP address from
the interface to the bridge. It's considered a dangerous operation because if
you're configuring the nodes remotely via SSH, you might be disconnected. It is
better to have console access to the nodes.

It'll be easier if the nodes have two network interfaces. For instance, the
`eth0` interface is for cluster management, we'll add the `eth1` interface to
the `br0` bridge:

```shell
sudo ip link set eth1 master br0
sudo ip link set br0 up
sudo ip link set eth1 up
```

These steps are required on each node if your cluster consists of multiple
nodes.

### Prepare Volumes

Download the cloud image of choice for the VM to boot up. Take Alma Linux as an
example:

```shell
wget http://ftp.tku.edu.tw/Linux/AlmaLinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
```

CDI introduces a new CRD - DataVolume. It's an abstraction on top of PVCs and
also an elegant way for users to populate data in PVCs for VMs' later use. There
are multiple ways to populate volumes. You can upload the cloud image via
`virtctl` to populate the VM disk:

```shell
virtctl image-upload dv almalinux \
    --size=10Gi \
    --image-path=AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 \
    --uploadproxy-url=https://$(kubectl -n cdi get svc cdi-uploadproxy -o jsonpath='{.spec.clusterIP}') \
    --insecure \
    --storage-class=local-path \
    --access-mode=ReadWriteOnce \
    --force-bind
```

Another way is to create the DataVolume object and specify the URL for it to
download the cloud image:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  annotations:
    cdi.kubevirt.io/storage.bind.immediate.requested: ""
  name: fedora
  namespace: default
spec:
  contentType: kubevirt
  source:
    http:
      url: "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2"
  storage:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 10Gi
    storageClassName: local-path
```

Additionally, you can create an empty volume with DataVolume's source specified
as `blank`. This will populate an empty volume as a VM disk. It's useful for
cases like PXE provisioning. I'm exploring the possibility of bringing
[Tinkerbell](https://tinkerbell.org/), KubeVirt, and
[KubeVirtBMC](https://github.com/starbops/kubevirtbmc) together to provision a
bunch of VMs with PXE as we did with bare metals.

### Fire Up VMs

With networking and storage all setup, we can finally create the VMs. The
following is a simple VirtualMachine that connects to the network we just
created, and using the PVC we populated with the cloud image as the VM disk.
Save the manifest as `vm1.yaml`:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    kubevirt.io/os: linux
  name: vm1
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: vm1
    spec:
      domain:
        cpu:
          cores: 2
        devices:
          disks:
          - disk:
              bus: virtio
            name: disk0
          - cdrom:
              bus: sata
              readonly: true
            name: cloudinitdisk
          interfaces:
          - name: default
            bridge: {}
            model: virtio
        machine:
          type: q35
        resources:
          requests:
            memory: 1024M
      networks:
      - name: default
        multus:
          networkName: net-101
      volumes:
      - name: disk0
        persistentVolumeClaim:
          claimName: fedora
      - cloudInitNoCloud:
          userData: |
            #cloud-config
            hostname: vm1
            ssh_pwauth: True
            password: password
            chpasswd: {expire: False}
          networkData: |
            network:
              version: 2
              ethernets:
                eth0:
                  dhcp4: false
                  addresses:
                  - 192.168.101.11/24
                  routes:
                  - to: 0.0.0.0/0
                    via: 192.168.101.1
                    on-link: true
                    type: unicast
                    metric: 100
                  mtu: 1500
                  nameservers:
                    addresses:
                    - 1.1.1.1
                    - 8.8.4.4
        name: cloudinitdisk
```

It's worth noting that the network configuration (in the form of cloud-init
network data) specified in the above VirtualMachine manifest is only suitable
for my own network environment. Keep in mind that the [bridge CNI
plugin](https://www.cni.dev/plugins/current/main/bridge/) is the actual plugin
that is in use for the VM. Multus CNI is just a meta plugin that leverages the
bridge CNI plugin. So, you should provide your own set of configurations for the
VM to have network connectivity.

Create the VirtualMachine object on the cluster with the command:

```shell
kubectl apply -f vm1.yaml
```

As soon as the VirtualMachine object is created, it'll be booted up. We can
observe the booting procedure with the VM console:

```shell
virtctl console vm1
```

Ideally, you can log in to the OS with the username and password
`fedora/password`.

## Wrapping Up

After going through the guide, hopefully, we're aware of the following:

-  What needs to be done before being able to kick off a VM in a Kubernetes
   cluster
-  What values Harvester provides

I hope this hands-on can give you some inspiration on how virtualization
technology fits in the cloud-native era.

## References

-  [cannot upload to DataVolume in WaitForFirstConsumer state, make sure the PVC
   is Bound · Issue #2645 ·
   kubevirt/containerized-data-importer](https://github.com/kubevirt/containerized-data-importer/issues/2645)
-  [containerized-data-importer/doc/waitforfirstconsumer-storage-handling.md at
   main ·
   kubevirt/containerized-data-importer](https://github.com/kubevirt/containerized-data-importer/blob/main/doc/waitforfirstconsumer-storage-handling.md)
