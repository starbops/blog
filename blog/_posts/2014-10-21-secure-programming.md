---
layout: post
title: 'Secure Programming 2014-10-21'
category: note
slug: secure-programming-20141021
---
2014/10/21 Secure Programming Class Note

## GNU Debugger Skill

```bash
(gdb) disassemble foo
(gdb) b *foo+40
(gdb) r
(gdb) display/i $pc
(gdb) x/10xw $ebp+0x10
(gdb) x/20xw $esp-0x20
(gdb) ni
(gdb) i b
```

## Buffer OverFlow

Disable stack guard

```bash
gcc -fno-stack-protector
```

Disable data execution prevention

```bash
gcc -z execstack
```

Disable address space layout randomization

```bash
echo 0 > /proc/sys/kernel/randomize_va_space
```
