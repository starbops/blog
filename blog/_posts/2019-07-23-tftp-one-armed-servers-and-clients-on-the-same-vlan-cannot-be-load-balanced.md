---
layout: post
title: 'TFTP One-Armed (Servers and Clients on The Same VLAN) cannot Be Load-Balanced'
category: memo
slug: tftp-one-armed-servers-and-clients-on-the-same-vlan-cannot-be-load-balanced
---
The way TFTP works, the client sends a UDP packet with a random source port destine to the server on port 69. The server responds with source port 69, however, instead of using the clinet port as a destination like most protocols, TFTP generates a random port number to send data traffic back to the client.

ACE tracks connections via MAC addresses, IP's and port numbers, and ingress/egress interfaces on a connection. When we send the packet out of the interface to the server, we are expecting a response back from to the clients port. To ACE, the port randomization the server is doing looks like a brand new UDP connection coming from the server.

As relates to load-balancing TFTP - the client is talking to the VIP and expects to receive a response from that IP. The server is talking to the client IP and is communicating with ACE. ACE has to catch the server's traffic destine to the client and modify the source IP from the server back to the VIP. When the server replies to the client connection with a new port, you can catch it with a class map that matches UDP source port 69 and source-NAT the packet to the VIP. That is what was being done above via this configuration:

```
class-map match-any TFTP
  10 match virtual-address 0.0.0.0 0.0.0.0 udp any

class NAT
  nat dynamic 2 vlan 212
```

However, with one-armed configurations, the gateway on the server is not ACE. That means, the client sends a packet to the VIP, the ACE forwards it to the server IP, the server sends its response back to the client. At that point, the client is confused because it was talking to the VIP, but received a response from the server IP. To mitigate that, you need to configure source NAT on the connection going from ACE to the server. That exact part is what makes it impossible to load-balance TFTP one-armed.

Think about this:

When you configure source NAT, many clients use one single IP. Source ports are changed to track which client belongs to which connection on the backend. (since all clients are going to use the same single IP between the ace and the server, how else are you going to track the connection?)

So, when the server is going to reply to the NAT pool IP and the destination port is going to be random - How exactly would the ACE know what client in the NAT table is supposed to receive that packet? It can't.

The only possible way to get this to work is configure policy based routing on the gateway to force any source port 69 traffic from the server back to the ACE so that ACE can un-NAT the traffic with a standard TFTP load-balancing configuration. In that manner, you are replacing the function of source NAT by routing. You just need to ensure that the packet goes into the interface that ACE egressed the first UDP packet to the server on.

## Reference

- [Re: How do I load balance TFTP between two servers and a client](https://supportforums.cisco.com/t5/application-networking/how-do-i-load-balance-tftp-between-two-servers-and-a-client-on/m-p/1674989/highlight/true#M33761)
