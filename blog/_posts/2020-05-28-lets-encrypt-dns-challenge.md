---
layout: post
title: "Automate Let's Encrypt DNS Challenge with Certbot and Gandi.net"
category: memo
slug: lets-encrypt-dns-challenge
---
It's always recommended to view web pages through HTTPS connections, even it's
just a static HTML page. So, as a content provider, it's my duty to host
websites with HTTPS. To enable HTTPS on the web server like Apache or Nginx,
valid certificates are required. In my case, I have bought and configured a
domain name on [Gandi.net](https://gandi.net) for my home cluster. It's better
to have different certificates for each service than having a single wildcard
certificate for all the services due to security concerns. However, I still use
wildcard certificate for one reason (I'll talk about it later). So in this
article I'm going to explain how to get TLS wildcard certificates with Let's
Encrypt using DNS validation.

## How DNS Validation of ACME Protocol Works

[Let's Encrypt](https://letsencrypt.org) is a well-known open project and
nonprofit certificate authority that provides TLS certificates to hundreds of
thousands of websites around the world. Let's Encrypt uses the ACME (Automatic
Certificate Management Environment) protocol to verify that one controls a given
domain name and to issue a certificate. There are mainly two ways to do that:

1. HTTP validation
1. DNS validation

Also, there are two types of domain name:

1. Fully-qualified domain names
1. Wildcard domain names

It's worth mentioning that currently, in API version 2, the only one way to get
certificates for wildcard domain names is through DNS validation. And I'm going
to get certificates for my services running inside of a private network, which
means I can only use DNS validation since the domain names I configured for my
services are not publicly reachable. Those DNS A records are mapped to private
IP addresses, so the HTTP validation is not applicable.

> I know it's not a good practice to expose your internal network architecture
> through registering public DNS records for private IP addresses. It leaks a
> great amount of valued information of your environment. But I have to say,
> it's super fuxking convenient! A legit way to do that is to have your own
> private DNS service which serves the private DNS records, and use it
> internally.

So, how does DNS validation of ACME protocol work? It's basically done by
manipulating TXT records. If you know how HTTP validation works (you should!),
it's the same. It makes you put a specific value in a TXT record so that you can
prove the ownership of the domain name you're requesting for a certificate.
After the validation is done, you clean up the TXT record. The website of Let's
Encrypt has a [good
explaination](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) of
it.

## Certbot Installation

First we need to install ACME client software to help us get the certificates.
There're [various implementation out
there](https://letsencrypt.org/docs/client-options/), and we choose the
recommended one, which is [certbot](https://certbot.eff.org).

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository universe
sudo add-apt-repository ppa:certbot/certbot
sudo apt update
sudo apt install certbot
```

Now the software has been installed, we should be able to get certificates
easily. For DNS validation, it will guide us to get the certificate in an
interactive way. I'll skip that since it's pretty straightforward.

## You Need Automation: Hooks

After going through the process of DNS validation manually we noticed that it's
just a pain in the ass. The steps are trivial and time-consuming. There must be
a way to automate that. And you're right!

You can use one of certbot's [DNS
plugins](https://certbot.eff.org/docs/using.html?highlight=dns#dns-plugins) to
achieve this. But unfortunately, my DNS provider, Gandi.net, does not provide a
usable plugin.

> By the time of writing, there's a [third-party
> plugin](https://github.com/obynio/certbot-plugin-gandi) which is not
> officially backed by Gandi.net. I'll give it a shot in the future. The value
> of this article is to show you how to do the automation with the APIs provided
> by Gandi.net and integrates it with certbot.

The way of plugin is not working, though. Certbot supports pre and post
validation hooks when running in manual mode. The hooks are external scripts
executed by certbot to perform the tasks related to DNS validation. It includes
two command line options `--manual-auth-hook` and `--manual-cleanup-hook`. Both
flags should be filled with the path to the hook scripts respectively. The main
idea is to place the ACME challenge to TXT record using Gandi.net's LiveDNS
API. And of course, to clean up the TXT record when the validation is done.

Here's the auth hook `authenticator.sh` written in Bash:

```bash
#!/usr/bin/env sh

APIKEY='your-api-key-here'

echo "${CERTBOT_DOMAIN}"
echo "${CERTBOT_VALIDATION}"

domain=$(echo "${CERTBOT_DOMAIN}" | rev | cut -d"." -f1-2 | rev)
subdomain=""

if [ "${domain}" = "${CERTBOT_DOMAIN}" ]; then
        echo 'Same!'
else
        echo 'Different!'
        subdomain=$(echo "${CERTBOT_DOMAIN}" | rev | cut -d"." -f3- | rev)
        subdomain_with_dot=".${subdomain}"
fi

result=$(curl -s -H "Authorization: Apikey $APIKEY" https://api.gandi.net/v5/livedns/domains/${domain}/records/_acme-challenge${subdomain_with_dot} | python -m json.tool)
if [ "${result}" = "[]" ]; then
        echo 'Newly created!'
        curl -s -X POST https://api.gandi.net/v5/livedns/domains/${domain}/records/_acme-challenge${subdomain_with_dot} \
                -H "Authorization: Apikey $APIKEY" \
                -H "Content-Type: application/json" \
                --data '{"rrset_type": "TXT", "rrset_values": ["'${CERTBOT_VALIDATION}'"], "rrset_ttl": "300"}'

else
        echo 'Append!'
        previous_validation=$(echo "${result}" | python -c "import sys, json; print json.load(sys.stdin)[0]['rrset_values'][0]" | tr -d '"')
        echo 'previsou_validation: '${previous_validation}
        curl -s -X PUT https://api.gandi.net/v5/livedns/domains/${domain}/records/_acme-challenge${subdomain_with_dot} \
                -H "Authorization: Apikey $APIKEY" \
                -H "Content-Type: application/json" \
                --data '{"items": [{"rrset_type": "TXT", "rrset_values": ["'${previous_validation}'", "'${CERTBOT_VALIDATION}'"], "rrset_ttl": "300"}]}'
fi

sleep 30
```

And the cleanup hook `cleanup.sh`:

```bash
#!/usr/bin/env sh

APIKEY='your-api-key-here'

echo "${CERTBOT_DOMAIN}"

domain=$(echo "${CERTBOT_DOMAIN}" | rev | cut -d"." -f1-2 | rev)
subdomain=""

if [ "${domain}" = "${CERTBOT_DOMAIN}" ]; then
        echo 'Same!'
else
        echo 'Different!'
        subdomain=$(echo "${CERTBOT_DOMAIN}" | rev | cut -d"." -f3- | rev)
        subdomain_with_dot=".${subdomain}"
fi

curl -s -X DELETE https://api.gandi.net/v5/livedns/domains/${domain}/records/_acme-challenge${subdomain_with_dot} \
        -H "Authorization: Apikey $APIKEY"
```

Just remember to put your valid [Gandi.net API
token](https://docs.gandi.net/en/domain_names/advanced_users/api.html) into the
scripts. I won't cover that, either.

Giving them executable bit:

```bash
chmod +x authenticator.sh cleanup.sh
```

The work has been done. It's time to integrate these hooks scripts with certbot
itself.

## Generating New Certificates

To generate a wildcard certificate for `internal.zespre.com`, try this:

```bash
$ sudo certbot certonly --manual \
    -d *.internal.zespre.com \
    -d internal.zespre.com \
    --manual-auth-hook authenticator.sh \
    --manual-cleanup-hook cleanup.sh \
    --preferred-challenges dns
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for internal.zespre.com
dns-01 challenge for internal.zespre.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
NOTE: The IP of this machine will be publicly logged as having requested this
certificate. If you're running certbot in manual mode on a machine that is not
your server, please ensure you're okay with that.

Are you OK with your IP being logged?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y
Output from authenticator.sh:
internal.zespre.com
0DrYgNTYVzuMexfppEz03-bL0H8V91Z7qi1NHfefZgs
Different!
Newly created!
{"message":"DNS Record Created"}
Output from authenticator.sh:
internal.zespre.com
vaTN_2ze9AJmBeW1Pe3_NUKsnOBakus8sN8mHmYHAkE
Different!
Append!
previsou_validation: 0DrYgNTYVzuMexfppEz03-bL0H8V91Z7qi1NHfefZgs
{"message":"DNS Record Created"}
Waiting for verification...
Cleaning up challenges
Output from cleanup.sh:
internal.zespre.com
Different!

Output from cleanup.sh:
internal.zespre.com
Different!

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/internal.zespre.com/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/internal.zespre.com/privkey.pem
   Your cert will expire on 2021-03-14. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le
```

If you look into the output you'll find that there are some messages about the
process of the validation. Here's a brief explanation:

![The Process of ACME DNS Challenge
Validation](/assets/images/lets-encrypt-dns-challenge/dns-challenge-validation.png)

Now that the newly generated private key and issued certificates are under the
directory `/etc/letsencrypt/live/<your-domain>/`. Make good use of them!

## Wrapping Up

In this article we have shown that how ACME DNS validation works, and adding
automation to certificate generation with the ability of certbot validation
hooks. So we can obtain wildcard certificates for our services running inside
private network. Hope you like it!

## References

-  [How It Works](https://letsencrypt.org/how-it-works/)
-  [利用 Let's Encrypt 來自動簽署並更新 SSL 憑證
   (wildcard)](https://medium.com/walkout/%E5%88%A9%E7%94%A8-lets-encrypt-%E4%BE%86%E8%87%AA%E5%8B%95%E7%B0%BD%E7%BD%B2%E4%B8%A6%E6%9B%B4%E6%96%B0-ssl-%E6%86%91%E8%AD%89-wildcard-26b49114bf73)
-  [Certbot 自動續約，自動驗證 DNS 域名所有權 - LiveDNS |
   哈部落](https://haway.30cm.gg/certbot-plugins-dns-gandi-livedns/)
-  [LiveDNS API](https://api.gandi.net/docs/livedns/)
-  [User Guide - Certbot 1.7.0.dev0
   documentation](https://certbot.eff.org/docs/using.html?highlight=hook#hooks)
-  [解析 Certbot（Let's encrypt）
   使用方式](https://andyyou.github.io/2019/04/13/how-to-use-certbot/)
-  [Need to suck TLD out of list of FQDN's using BASH
   script](https://stackoverflow.com/questions/14368658/need-to-suck-tld-out-of-list-of-fqdns-using-bash-script)
