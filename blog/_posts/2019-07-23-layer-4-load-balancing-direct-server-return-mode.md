---
layout: post
title: 'Layer 4 Load Balancing Direct Server Return Mode'
category: note
slug: layer-4-load-balancing-direct-server-return-mode
---
Direct server return is usually shortened to DSR.

In DSR mode, the load-balancer routes packets to the backends without changing
anything in it but the destination MAC address. The backends process the
requests and answer directly to the clients, without passing through the
load-balancer.

The backends must have the service IP configured on a loopback to be able to
accept the requests.

## TCP Connection Overview

![Layer 4 DSR TCP Connection](/assets/images/layer-4-load-balancing-direct-server-return-mode/layer4-dsr-tcp-connection.png)

As usual when performing layer 4 load-balancing, the TCP connection is
established directly between the client and the backend. Note that the requests
pass through the load-balancer while the responses not.

## Data Flow

![Layer 4 DSR Data Flow](/assets/images/layer-4-load-balancing-direct-server-return-mode/layer4-dsr-data-flow.png)

As explained above, the load-balancer sees only the requests and just change the
destination MAC address of the packets. The backends answers directly to the
client using the service IP configured on a loopback interface.

## Pros and Cons

### Pros

-  Very fast load-balancing mode
-  Load-balancer network bandwidth is not a bottleneck anymore
-  Total output bandwidth is the sum of each backend bandwidth
-  Less intrusive than layer 4 load-balancing NAT mode

### Cons

-  The service VIP must be configured on a loopback interface on each backend
   and must not answer to ARP requests
-  No layer 7 advanced features are available

## When Use This Architecture

-  Where response time matters
-  Where no intelligence is required
-  When output capacity of the load-balancer could be the bottleneck

## Reference

-  [layer 4 load balancing direct server return mode](https://www.haproxy.com/blog/layer-4-load-balancing-direct-server-return-mode/)
