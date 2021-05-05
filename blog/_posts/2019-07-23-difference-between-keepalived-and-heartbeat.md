---
layout: post
title: 'Difference between Keepalived and Heartbeat'
category: memo
slug: difference-between-keepalived-and-heartbeat
---
Heartbeat is not the best tool to get a redundant haproxy setup, it was designed to build clusters, which is a lot different from having two redundant stateless network equipments. Network oriented tools such as keepalived or ucarp are the best suited for that task.

The difference between those two families is simple:

1. A cluster-oriented product such as **heartbeat** will ensure that a shared resource will be present at *at most* one place. This is very important for shared filesystems, disks, etc... It is designed to take a service down on one node and up on another one during a switchover. That way, the shared
resource may never be concurrently accessed. This is a very hard task to accomplish and it does it well.
2. A network-oriented product such as **keepalived** will ensure that a shared IP address will be present at *at least* one place. Please note that I'm not talking about a service or resource anymore, it just plays with IP addresses. It will not try to down or up any service, it will just consider a certain number of criteria to decide which node is the most suited to offer the service. But the service must already be up on both nodes. As such, it is very well suited for redundant routers, firewalls and proxies, but not at all for disk arrays nor filesystems.

## Reference

- [What is the difference between keepalive and heartbeat?](https://serverfault.com/questions/361071/what-is-the-difference-between-keepalive-and-heartbeat)
