---
layout: post
title: 'Adding Self-signed Certificate for Java Application on Windows'
category: note
slug: adding-self-signed-certificate-for-java-application-on-windows
---
In addition to import self-signed certificate into system, you need to import it
to another place. That's called Java **truststore**.

![Java Truststore](/assets/images/adding-self-signed-certificate-for-java-application-on-windows/self-signed-certificate-certlm.png)

[Here's one little Java class
file](https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class)
called `SSLPoke.class` to let you check if you can connect the target with SSL
(whatever HTTPS, LDAPS, POP3S, etc.).

```powershell
C:\Users\nobody\Downloads>java SSLPoke repo.maven.apache.org 443
sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
        at sun.security.validator.PKIXValidator.doBuild(Unknown Source)
        at sun.security.validator.PKIXValidator.engineValidate(Unknown Source)
        at sun.security.validator.Validator.validate(Unknown Source)
        at sun.security.ssl.X509TrustManagerImpl.validate(Unknown Source)
        at sun.security.ssl.X509TrustManagerImpl.checkTrusted(Unknown Source)
        at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(Unknown Source)
        at sun.security.ssl.ClientHandshaker.serverCertificate(Unknown Source)
        at sun.security.ssl.ClientHandshaker.processMessage(Unknown Source)
        at sun.security.ssl.Handshaker.processLoop(Unknown Source)
        at sun.security.ssl.Handshaker.process_record(Unknown Source)
        at sun.security.ssl.SSLSocketImpl.readRecord(Unknown Source)
        at sun.security.ssl.SSLSocketImpl.performInitialHandshake(Unknown Source)
        at sun.security.ssl.SSLSocketImpl.writeRecord(Unknown Source)
        at sun.security.ssl.AppOutputStream.write(Unknown Source)
        at sun.security.ssl.AppOutputStream.write(Unknown Source)
        at SSLPoke.main(SSLPoke.java:31)
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
        at sun.security.provider.certpath.SunCertPathBuilder.build(Unknown Source)
        at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(Unknown Source)
        at java.security.cert.CertPathBuilder.build(Unknown Source)
        ... 16 more
```

Normally it should be like the following:

```powershell
C:\Users\nobody\Downloads>java SSLPoke repo.maven.apache.org 443
Successfully connected
```

## System Java Version

Firstly, check current Java version.

```powershell
C:\>java -version
java version "1.8.0_191"
Java(TM) SE Runtime Environment (build 1.8.0_191-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.191-b12, mixed mode)
```

The certificate must be imported into the correct version of Java's `cacerts`
file, or there will be no effect.

## Java's Root Certificate Authority (CA)

Dump out current trusted root certificates with `changeit` password.

```powershell
C:\Program Files\Java\jre1.8.0_191\bin>keytool.exe -list -v -keystore ../lib/security/cacerts > ../lib/security/java_cacerts.txt
```

Import the self-signed certificate with `changeit` password.

```powershell
C:\Program Files\Java\jre1.8.0_191\bin>keytool.exe -import -alias zenoss -keystore ../lib/security/cacerts -file C:\Users\nobody\Downloads\zenoss.cer
```

Dump out trusted root certificates again to see whether we have succeeded import
the self-signed certificate or not.

```powershell
C:\Program Files\Java\jre1.8.0_191\bin>keytool.exe -list -v -keystore ../lib/security/cacerts > ../lib/security/java_cacerts.txt
```

## References

-  [PKIX path building failed: SunCertPathBuilderException: unable to find valid
   certification path to requested
   target.](http://magicmonster.com/kb/prg/java/ssl/pkix_path_building_failed.html)
-  [https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html](https://confluence.atlassian.com/kb/unable-to-connect-to-ssl-services-due-to-pkix-path-building-failed-error-779355358.html)
