---
title: ZooKeeper 3-Node Cluster Installation Guide
category: note
slug: zookeeper-3-node-cluster-installation-guide
date: 2020-01-15
---
## Introduction

ZooKeeper is commonly used in distributed systems to manage configuration
information, naming services, distributed synchronization, quorum, and state. In
addition, distributed systems rely on ZooKeeper to implement consensus, leader
election, and group management.

In a production environment, **each ZooKeeper node should be run on separate
host.** This prevents service disruption due to host hardware failure or
reboots. This is an important and necessary architectural consideration for
building a resilient and highly available distributed system.

## Specs

-  3-node deployment
-  Ubuntu 18.04.3 LTS
-  4 vCPUs
-  4 GB RAM
-  32 GB disk
-  1 NIC

## Prerequisites

Install OpenJDK on all 3 nodes.

```bash
sudo apt install openjdk-8-jdk
```

## Installation

### Creating Dedicated User for ZooKeeper

```bash
sudo useradd zk -m
sudo usermod --shell /bin/bash zk
sudo passwd zk
sudo usermod -aG sudo zk
```

### Configuring SSH Daemon

In `/etc/ssh/sshd_config`:

```text
PermitRootLogin no
DenyUsers zk
```

```bash
sudo systemctl restart sshd.service
```

Switch to the zk user for the rest steps.

### Creating Data Directory for ZooKeeper

```bash
sudo mkdir -p /data/zookeeper
sudo chown zk:zk /data/zookeeper
```

### Downloading and Extracting the ZooKeeper Binaries

```bash
cd /opt
sudo wget http://ftp.mirror.tw/pub/apache/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz
sudo tar -zxvf zookeeper-3.4.14.tar.gz
sudo chown zk:zk -R zookeeper-3.4.14
sudo ln -s zookeeper-3.4.14 zookeeper
sudo chown -h zk:zk zookeeper
```

### Configuring ZooKeeper

In `/opt/zookeeper/conf/zoo.cfg`:

```text
tickTime=2000
dataDir=/data/zookeeper
clientPort=2181
maxClientCnxns=60
```

### Starting ZooKeeper and Testing the Standalone Installation

Start ZooKeeper with the `[zkServer.sh](http://zkserver.sh)` command.

```bash
cd /opt/zookeeper
bin/zkServer.sh start
```

Connect to the local ZooKeeper server with the following command:

```bash
bin/zkCli.sh -server 127.0.0.1:2181
```

After you've done some testing using the client, you will close the client
session and shut down the ZooKeeper service.

```bash
bin/zkServer.sh stop
```

### Creating and Using a Systemd Unit File

In `/etc/systemd/system/zk.service`:

```text
[Unit]
Description=ZooKeeper Daemon
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
Type=forking
WorkingDirectory=/opt/zookeeper
User=zk
Group=zk
ExecStart=/opt/zookeeper/bin/zkServer.sh start /opt/zookeeper/conf/zoo.cfg
ExecStop=/opt/zookeeper/bin/zkServer.sh stop /opt/zookeeper/conf/zoo.cfg
ExecReload=/opt/zookeeper/bin/zkServer.sh restart /opt/zookeeper/conf/zoo.cfg
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=default.target
```

```bash
sudo systemctl start zk.service
sudo systemctl enable zk.service
```

### Configuring a Multi-Node ZooKeeper Cluster

In `/opt/zookeeper/conf/zoo.cfg`, append the following configurations on each of
the three nodes:

```text
initLimit=10
syncLimit=5
server.1=zookeeper-1.bampi.net:2888:3888
server.2=zookeeper-2.bampi.net:2888:3888
server.3=zookeeper-3.bampi.net:2888:3888
```

Create `/data/zookeeper/myid` with their corresponding IDs, for example
`zookeeper-1`:

```text
1
```

### Running and Testing the Multi-Node Installation

To start a quorum node, first change to the `/opt/zookeeper` directory on each
node:

```bash
cd /opt/zookeeper
java -cp zookeeper-3.4.13.jar:lib/log4j-1.2.17.jar:lib/slf4j-log4j12-1.7.25.jar:lib/slf4j-api-1.7.25.jar:conf org.apache.zookeeper.server.quorum.QuorumPeerMain conf/zoo.cfg
```

Then you can test each node with `zkCli.sh`.

## References

-  [How To Install and Configure an Apache ZooKeeper Cluster on Ubuntu 18.04 |
   DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-an-apache-zookeeper-cluster-on-ubuntu-18-04)
