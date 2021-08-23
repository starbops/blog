---
layout: post
title: 'Computer Networks 2014-09-24'
category: note
slug: computer-networks-20140924
---
2014/09/24 Computer Networks Class Note

```text
         circuit       hard-state      soft-state      stateless
         switching     switching       switching       routing
    stateful|---------------+--------------+---------------|stateless
          POTS     |       ATM           MPLS          Internet
                   |                                   (packet
               C/S | P/S                                switching)
```

-  ISPs change part of backbone into MPLS
-  store and forward
-  when a packet arrived
   -  store in a queue (waiting time)
   -  waiting to be processed
   -  queue for output port (waiting time)
   -  **transmitted (transmission time)**
   -  ~~~~ (propagation time)

-  how fast I can speak: transmission time

-  jitter: latency variation
-  throughput: how much you can transmit
