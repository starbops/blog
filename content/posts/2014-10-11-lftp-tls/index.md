---
title: Using lftp with TLS Enabled
category: memo
slug: lftp-tls
date: 2014-10-11
---
It is hard to find a command-line-based ftp client that support SSL/TLS.

## Installation

### FreeBSD

Enable the TLS by checking the box in the configure dialog

```bash
portmaster ftp/lftp
```

### Arch Linux

```bash
abs
mkdir ~/abs
cp -r /var/abs/lftp ~/abs
cd ~/abs/lftp
```

We need to modify the PKGBUILD of lftp

```text
...
depends=('gcc-libs' 'readline' 'openssl' 'expat' 'sh')
...
build() {
    cd ${pkgname}-${pkgver}
    ./configure --prefix=/usr \
        --without-gnutls \
        --with-openssl \
        --without-included-regex \
        --disable-static
    make
}
...
```

Compile our patched source code of lftp. After that, install with the package
which we built.

```bash
makepkg -s
pacman -U lftp-4.5.5-1-x86_64.pkg.tar.xz
```

### Mac OS X

First, update Homebrew formula by `brew update`. When it is done, just
install it through `brew install lftp`.
