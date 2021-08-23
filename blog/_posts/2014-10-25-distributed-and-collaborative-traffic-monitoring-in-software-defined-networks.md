---
layout: post
title: 'Distributed and Collaborative Traffic Monitoring in Software Defined Networks'
category: note
slug: distributed-and-collaborative-traffic-monitoring-in-software-defined-networks
---
20141029 Wireless Internet Laboratory meeting

## Abstraction

-  Two representative monitoring tasks
   -  Flow size counting
   -  Packet sampling

-  Distributed and Collaborative Monitoring system (DCM)
   -  Allows switches to collaboratively achieve
      -  Flow monitoring tasks
      -  Balance measurement load
   -  Performs per-flow monitoring
      -  Different groups of flows are monitored using different actions
   -  Memory-efficient solution for switch data plane

-  Highest measurement accuracy given the same memory budget of switches

## Introduction

-  In most networks, routers/switches independently monitor flows
   -  Switches may consumes tremendous resources
   -  Some flows may not be covered by these switches

-  A monitoring rule includes
   -  Matching fields
   -  An action applied to the flow

-  Two essensial requirements of traffic monitoring
   -  Load distribution
   -  Per-flow monitoring

The only two approaches that can achieve per-flow monitoring and load
distribution are rule-based and aggregation-based flow monitoring.

-  Rule-based flow monitoring
   -  Limited by the switch memory space
-  Aggregation-based monitoring
   -  Still requires a large rule table
   -  Potential duplicate samples may occur
   -  Changes of small flows are hard to observe

## Existing Traffic Measurement Tools

NetFlow and sFlow support generic measurement tasks based on packet sampling.
Many applications, however, require per-flow monitoring, i.e., different
monitoring actions performed on diffenent flows.

### NetFlow

Netflow is a feature that was introduced on Cisco routers that provides the
ability to collect IP network traffic as it enters or exits an interface. By
analyzing the data provided by Netflow a network administrator can determine
things such as the source and destination of traffic, class of service, and the
causes of congestion. Netflow consists of three components: flow caching, Flow
Collector, and Data Analyzer.

### sFlow

sFlow, short for "sampled flow", is an industry standard for packet export at
Layer 2 of the OSI model. It provides a means for exporting truncated packets,
together with interface counters.

Two types of sampling:

-  Random sampling of packets or application layer operations
-  Time-based sampling of counters

## System Design

DCM guarantees the following two properties

1. Every packet of a targeted flow should be monitored by at least one switch
   on its path
1. If a packet is monitored by more than one switches, duplicate monitoring can
   be detected

### Model

-  Flows are identified by the 5-tuple, i.e., <SrcIp, DstIp, SrcPort, DstPort,
   Protocol>
-  There is a centralized SDN controller maintaining a monitoring table
   -  The targeted flows
   -  The corresponding monitor actions
-  A switch records measurement results in its local memory and reports the
   results to the controller periodically

### Assumption

The memory space for monitoring tasks in a switch is limited while the
controller has enough space to store detailed flow information and monitor
actions.

### DCM Data Plane on Switches

The flow-to-filter matching are based on the hash of a 5-tuple. The DCM
component does not perform any packet forwarding task.

1. A wildcard rule applies an action to an aggregate of flows
1. The function of the admission Bloom filter (admBF) is to filter the flows
   that are not of interest
1. The action Bloom filters (actBFs) decides the corresponding monitoring
   actions

### Controller Operations

-  Monitoring load allocation
-  Bloom filter contruction and updates
   -  Real-time Addition and Periodical Reconstruction (RAPR)
      -  Add immediately
      -  Reconstruct periodically
-  False positive detection
   -  DCM can control false positive rates, but cannot completely eliminate
      false positives
   -  The controller can maintain copies of Bloom filters installed on switches
      and the record of flow information
      -  Detect all false positives
      -  Limit the negative influence of them

### Reference

-  [Distributed and Collaborative Traffic Monitoring in Software Defined Networks](http://conferences.sigcomm.org/sigcomm/2014/doc/slides/197.pdf)
