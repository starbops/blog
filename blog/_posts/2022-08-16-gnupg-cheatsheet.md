---
layout: post
title: 'GnuPG Cheatsheet'
category: note
slug: gnupg-cheatsheet
---
These are important but not so commonly used. Therefore, I noted down some
critical parts of it in case I need them in the future.

## Create Keys

The interactive way:

```bash
gpg --expert --full-gen-key
```

## Delete Keys

### Delete Subkeys

```bash
$ gpg --edit-key $KEYID
gpg> list
gpg> key 1
gpg> delkey
gpg> save
```

### Delete Specific Secret Keys

```bash
$ gpg-connect-agent "HELP DELETE_KEY" /bye
# DELETE_KEY [--force|--stub-only] <hexstring_with_keygrip>
#
# Delete a secret key from the key store.  If --force is used
# and a loopback pinentry is allowed, the agent will not ask
# the user for confirmation.  If --stub-only is used the key will
# only be deleted if it is a reference to a token.
OK
```

To delete a specific secret key (secret master key or secret subkey), you have
to first obtain the target secret key's keygrip. Then use the keygrip to delete
the correct secret key:

```bash
gpg --list-secret-keys --with-keygrip starbops@hey.com
gpg-connect-agent "DELETE_KEY $KEYGRIP" /bye
```

### Sign Data

Content with signature in binary format (generates `$FILE.gpg`):

```bash
gpg --local-user $SIGNING_KEYID --sign $FILE
```

Content with signature in ASCII format (generates `$FILE.asc`):

```bash
gpg --local-user $SIGNING_KEYID --sign --armor $FILE
```

Content followed by signature in ASCII format (generates `$FILE.asc`):

```bash
gpg --local-user $SIGNING_KEYID --clear-sign $FILE
```

Only signature in binary format (generates `$FILE.gpg`):

```bash
gpg --local-user $SIGNING_KEYID --detach-sign $FILE
```

Only signature in ASCII format (generates `$FILE.asc`):

```bash
gpg --local-user $SIGNING_KEYID --detach-sign --armor $FILE
```

## Interact with Other People

When you go to some key-signing parties, you might exchange fingerprints with
people (maybe it's on your business card)

### Upload Public Keys

There're several public GPG key servers. You have to upload your public key to
one of them.

-  keyserver.ubuntu.com
-  keys.openpgp.org
-  pgp.mit.edu
-  pgp.uni-mainz.de
-  pgp.net.nz

```bash
gpg --keyserver $KEYSERVER --send-keys $KEYID
```

### Download Other People's Public Key

```bash
gpg --keyserver $KEYSERVER --recv-keys $KEYID
```

Or, if you don't know what the ID is for the key, specify the UID (email
address):

```bash
gpg --keyserver $KEYSERVER --search-keys $UID
```

After you download their public keys, you could check their signatures, sign
them, or use them to encrypt data, then transfer the protected data back to
their owner via email. Lots of things could be done!

Oh, BTW, if you encounter any `Network is unreachable` issue during sending,
receiving, or even searching keys on any keyserver, try
[this](https://stackoverflow.com/questions/67251078/gpg-keyserver-send-failed-no-keyserver-available-when-sending-to-hkp-pool).
Make sure you add this line in your `~/.gnupg/dirmngr.conf`:

```plaintext
standard-resolver
```

To make the config take effect, reload `dirmngr` process by:

```bash
gpgconf --reload dirmngr
```

Now you should be all good. I encountered this on my M1 Mac mini environment.
Not sure what the root cause is. Maybe it's a bug on the M1 version of gpg.

### Sign Public Keys

Signing other people's public keys is a very serious thing. You should check the
key's fingerprint with its owner face to face. If not possible, schedule a video
meeting. This is to keep the authenticity of the key, making sure that the key
owner owns the key you're going to sign.

To sign a public key, you can do the following (if you have multiple keys in
your GPG keyring, you have to decide which key is the signing key with
`--default-key $SIGNING_KEYID` or `--local-user $SIGNING_KEYID`):

```bash
gpg --local-user $SIGNING_KEYID --sign-key $TARGET_KEYID
```

Or, if you prefer the interactive way:

```bash
$ gpg --local-user $SIGNING_KEYID --edit-key $TARGET_KEYID
gpg> list
gpg> sign
gpg> save
```

### Check Key Signature

```bash
gpg --check-sigs $KEYID
```

## References

-  [Delete secret
   subkeys](https://security.stackexchange.com/questions/207138/how-do-i-delete-secret-subkeys-correctly)
-  [Delete subkeys (pub +
   secret)](https://superuser.com/questions/1132263/how-to-delete-a-subkey-on-linux-in-gnupg)
-  [Choose different secret keys to sign different public
   keys](https://lists.gnupg.org/pipermail/gnupg-users/2004-May/022471.html)
-  [Signing
   keys](https://unix.stackexchange.com/questions/644304/key-signing-cant-see-new-signatures)
-  [Signing someone's GPG key](https://gist.github.com/F21/b0e8c62c49dfab267ff1d0c6af39ab84)
