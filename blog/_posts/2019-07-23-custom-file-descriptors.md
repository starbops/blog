---
layout: post
title: 'Custom File Descriptors'
category: note
slug: custom-file-descriptors
---

```bash
$ echo "This is an input test" > test.txt
$ exec 3< test.txt
$ cat <&3
This is an input test
```

```bash
$ exec 4> test.txt
$ echo "This is a truncate write test" >&4
$ cat test.txt
This is a truncate write test
```

```bash
$ exec 5>> test.txt
$ echo "This is an append write test" >&5
$ cat test.txt
This is a truncate write test
This is an append write test
```

```bash
exec 3<&-
exec 4<&-
exec 5<&-
```

## References

-  [Playing with file descriptors and redirection](https://www.packtpub.com/mapt/book/networking_and_servers/9781785881985/1/ch01lvl1sec14/playing-with-file-descriptors-and-redirection)
-  [How to close file descriptor via Linux shell command](https://stackoverflow.com/questions/5987820/how-to-close-file-descriptor-via-linux-shell-command)
