---
layout: post
title: 'Network Programming 2014-10-09'
category: note
slug: network-programming-20141009
---
2014/10/09 Network Programming Class Note

- Return value of `read()` equals 0 means that it is the end (blocking mode)
    - pipe: the write end has been closed
    - file: end of file
- create pipe 時 read 的 FD 先於 write 的 FD, e.g. read = 3 and write = 4
- `cat f1 | sort | lpr`
    - csh
        - csh fork 3 children
        - csh create 2 pipes
        - close unused resources, i.e. 4-6
    - child1 (cat): 不修改到原來程式的前提下竄改 FD table 中的 stdout
        - close 1
        - dup 4: to replace stdout (FD table round-robin)
        - close 3-6: avoid side effect (referencing)
        - exec cat
    - child2 (sort): 不修改到原來程式的前提下竄改 FD table 中的 stdin & stdout
        - close 1-2
        - dup 3: to replace stdin
        - dup 6: to replace stdout
        - close 3-6
        - exec sort
    - child3 (lpr): 不修改到原來程式的前提下竄改 FD table 中的 stdin
        - close 2
        - dup 5
        - close 3-6
        - exec lpr

FD table in above example

```
+---+---------------+
| 0 | stdin         |
+---+---------------+
| 1 | stdout        |
+---+---------------+
| 2 | stderr        |
+---+---------------+
| 3 | pipe 1 read   |
+---+---------------+
| 4 | pipe 1 write  |
+---+---------------+
| 5 | pipe 2 read   |
+---+---------------+
| 6 | pipe 2 write  |
+---+---------------+
```

- If you do not close unused read end or write end of a pipe, you may encounter
  some throny problems.
