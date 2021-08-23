---
layout: post
title: 'A Workaround to Fix The Unsigned JNLP Issue after Java Version 8 Update 131'
category: memo
slug: a-workaround-to-fix-the-unsigned-jnlp-issue-after-java-version-8-update-131
---
After installing whole new Windows 10 on my new computer, I installed Oracle
Java version 8 update 162, which made me unable to use BMC Java console. Due to
security policy, new version Java disable `MD5withRSA` by default.

Comment out the following line in `C:\\Program
Files\Java\jre1.8.0_162\lib\security\java.security`:

```text
#jdk.jar.disabledAlgorithms=MD2, MD5, RSA keySize < 1024, DSA keySize < 1024
```

And you can use BMC Java console again.

## Reference

-  [a quick workaround to fix the unsigned JNLP issue after Java upgraded to
   version 8 update
   131](https://wuzhaojun.wordpress.com/2017/05/05/a-workaround-to-fix-unsigned-jnlp-issue-after-upgrade-java-to-version-8-update-131/)
