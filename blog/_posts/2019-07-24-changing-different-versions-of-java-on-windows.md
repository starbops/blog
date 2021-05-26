---
layout: post
title: 'Changing Different Versions of Java on Windows'
category: note
slug: changing-different-versions-of-java-on-windows
---
Check path environment variable

![Path Environment Variable](/assets/images/changing-different-versions-of-java-on-windows/path-environment-variable.png)

Check Java home environment variable

![Java Home Environment Variable](/assets/images/changing-different-versions-of-java-on-windows/java-home-environment-variable.png)

Replacing the following three files under `C:\Program Files (x86)\Common Files\Oracle\Java\javapath` with the right ones.

- `java.exe`
- `javaw.exe`
- `javaws.exe`

Configuring registry settings using `regedit.exe`:

```
Key: HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft\Java Runtime Environment
Name: CurrentVersion
Value: 1.8
```
