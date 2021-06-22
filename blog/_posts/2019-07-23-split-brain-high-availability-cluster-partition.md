---
layout: post
title: 'Split Brain: High Availability Cluster Partition'
category: note
slug: split-brain-high-availability-cluster-partition
---
A split-brain condition is the result of a Cluster Partition, where each side
believes the other is dead, and then proceeds to take over resources as though
the other side no longer owned any resources.

After this, a variety of Bad Things Will Happen - including destroying shared
disk data.

This is the result of acting on incomplete information - neglecting Dunns Law.
That is, when a node is declared "dead", its status is, by definition, not
known. Perhaps it is dead. perhaps it is merely incommunicado. The only thing
that is known is that its status is not known.

The ultimate cure to this is to use Fencing and lock the other side out.

The problem with merely using quorum without fencing, is that the loss of quorum
can take an unbounded amount time to detect and react to in the worst case.

Fencing does not require knowledge of the timing or behavior of the "errant"
nodes, nor does it require the cooperation or sanity of errant nodes. In
addition, fencing operations receive positive confirmation. Hence, fencing has a
high degree of certainty.

A good way of avoiding split brain conditions in most cases without having to
resort to fencing is to configure redundant and independent cluster
communications paths - so that loss of a single interface or path does not break
communication between the nodes - that is the communications should not have a
single point of failure (SPOF).

Using both redundant communications and fencing is a good way to go. We highly
recommend both.
