---
layout: post
title: 'Network Programming 2014-10-16'
category: note
slug: network-programming-20141016
---
2014/10/16 Network Programming Class Note

## Byte Order

-  Little endian: int -> short is convenient (still implemented in most PCs)
-  Big endian: straight forward, hence become main trend
   (media formats, networking)

```text
          |   |                 Big endian
A ------> |   | 0 1               A  A+1 A+2 A+3
A + 1 --> |   | 0 0             +---+---+---+---+
A + 2 --> |   | 0 0             | 0 | 0 | 0 | 1 |
A + 3 --> |   | 1 0             +---+---+---+---+
          |   |                  A+3 A+2 A+1  A
                                Little endian
```

-  Circuit switching: telephone system
-  Packet switching: IP
-  Virtual circuit switching: TCP (each packet may not go through same path)

## Buffer in Network Programming

Send/receive buffers are normally in 2 KB, 4 KB, or 8 KB size. We use 4 KB for
example.

-  Define of a successfully `write()`: write to send buffer, not transmit
   -  3 KB full, write 2 KB => return length of successfully written data, then
      continue
   -  4 KB full, write 2 KB => blocked until send buffer is available again
-  Define of a successfully `read()`: read from receive buffer as long as
   data arrive receive buffer (even buffer is not full)

## Socket Programming

-  `htons()`: host to network short
