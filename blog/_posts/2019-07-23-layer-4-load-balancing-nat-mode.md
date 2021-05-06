---
layout: post
title: 'Layer 4 Load Balancing NAT Mode'
category: note
slug: layer-4-load-balancing-nat-mode
---
NAT stands for Network Address Translation.

In the NAT mode, the load-balancer will route traffic between user and server by changing destination IP address of the packets.

## TCP Connection Overview

TCP connection is established between the client and the server. The load-balancer just ensures a client is always forwarded to the same server.

![Layer4 NAT TCP Connection](/assets/images/layer-4-load-balancing-nat-mode/layer4-nat-tcp-connection.png)

## Data Flow

As shown below, the clients get connected to the **service VIP**. The load-balancer chooses a server in the pool then forwards packets to it by changing destination IP address.

![Layer4 NAT Data Flow](/assets/images/layer-4-load-balancing-nat-mode/layer4-nat-data-flow.png)

## Pros and Cons

### Pros

- Fast load balancing
- Easy to deploy

### Cons

- Infrastructure intrusive: need to change the default gateway of the servers
- The server default gateway must use the load balancer, in order to do reverse NAT operation
- Output bandwidth is limitated by load balancer output capacity

## When Use This Architecture?

- When output capacity of the load balancer won't be a bottleneck in a near future
- When nothing but the default gateway of the servers can be changed

## References

- [Layer 4 load balancing NAT mode](https://www.haproxy.com/blog/layer-4-load-balancing-nat-mode/)
