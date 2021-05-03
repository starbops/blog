---
layout: post
title: 'Setup OmniUI with UDS'
category: memo
slug: setup-omniui-with-uds
---
## Mininet

[Mininet][1] is a network simulator, running real kernel, switch, and application
code. It is useful for developing, teaching, and research. You can simply
manipulate the entire virtual network by command line interface or [programming
API][2].

Download Mininet virtual machine image from Mininet's official website. Then
import the uzipped image to your VMware, VirtualBox, etc. Using account/password
both are "mininet" to login into the black box, weeeeee!

## OmniUI

OmniUI is a diagnosis, analytic, and management framework for Software-Defined
Networks. It provides graphical user interface to illustrate information of
flows, devices and statistic data. Features of OmniUI includes:

- Compatible with various controller
- Forwarding path of specific flow
- Topology view with traffic information
- Statistic data of specific flow
- Statistic data of specific port/link
- Dynamic flow migration

OmniUI has three major components:

- Web UI: self-explanatory
- Core: provides many resources such as event registration, RESTful API
  registration and service, IPC (actually IMC, Inter Module Communication),
  etc.
- Controller adapter: Per-controller application, to unify data format of
  various types of controller.

More details please refer to the GitHub page of [OmniUI][3].

To install OmniUI in your box, some dependency issues have to be solved first.

```bash
# apt-get install python-pip
# pip install Flask
# pip install Flask-Cors
# pip install pymongo
```

Using Git to clone the repository on GitHub. Then change the current branch to
"dev" branch which contains User-Defined Statistics (UDS) feature.

```bash
$ git clone https://github.com/dlinknctu/OmniUI.git
$ cd OmniUI && git checkout dev
```

## Trema-Edge

Trema is a full-stack, easy-to-use framework for developing OpenFlow
controllers in Ruby and C. But Trema currently supports OpenFlow version 1.0
only. However, OmniUI implements UDS using multiple table feature provided by
OpenFlow version 1.3.

To resolve this situation, one workaround is using Trema-Edge as OmniUI's
controller. Trema-Edge is the bleeding-edge of Trema, written in C but also has
a release of Ruby version. Currently, it supports OpenFlow 1.3 only.

```bash
$ git clone https://github.com/trema/trema-edge.git
```

This repository has only been tested with ruby 2.0.0 and will not work with
1.8.x. So the Ruby Version Manager (RVM) will be your good friend if don't want
to mess up your ruby environment. Install RVM for better ruby and packages
management:

```bash
$ gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
$ \curl -sSL https://get.rvm.io | bash -s stable
$ echo "source $HOME/.rvm/scripts/rvm" >> ~/.bash_profile
```

Then re-login you will have `rvm` on the go. Use `rvm help` to see the
commands available. Before building the controller, some dependencies have to
be resolved.

```bash
# apt-get install gcc make libpcap-dev libssl-dev
$ gem install bundler
$ bundle install
$ rake
```

## Adapter for Trema-Edge From OmniUI

Install the packages required by Trema-Edge adapter:

- pkg-config
- json-c

```bash
# apt-get install pkg-config
$ git clone https://github.com/json-c/json-c.git
$ cd json-c
$ sh autogen.sh
$ ./configure
$ make
# make install
```

The controller adapter of Trema-Edge provided by OnmiUI resides in
`~/OmniUI/adapter/trema/uds`. Just copy them into the directory of
Trema-Edge. Then build the UDS application.

```bash
$ cp -R ~/OmniUI/adapter/trema/uds ~/trema-edge/
$ cd ~/trema-edge/uds
$ make
```

After the UDS application was built, run the controller along with our UDS
application:

```bash
$ cd ~/trema-edge
$ ./trema run uds/src/uds
```

Trema listens on port 6653. Now use Mininet to populate desired virtual
network.

```bash
# mn --controller=remote,port=6653 --topo=tree,2
```

At this time, the connection between any two hosts will still not work. Because
the switches (OVS) couldn't understand OpenFlow 1.3 protocol. They cannot
communicate with the controller.

## OVS with OpenFlow 1.3

Trema-Edge controller is compatible with OpenFlow 1.3 switch. To turn mininet's
OVS to support OpenFlow 1.3, we need to configure all the OVS spawn by mininet.

```bash
# ovs-vsctl show | grep Bridge | awk -F "\"" '{print $2}' | xargs -i  ovs-vsctl set bridge {} protocols=OpenFlow10,OpenFlow12,OpenFlow13
```

That's all.

## References

- [rvm][4]
- [json-c][5]
- [trema-edge][6]

[1]: http://mininet.org
[2]: https://github.com/mininet/mininet/wiki/Introduction-to-Mininet
[3]: https://github.com/dlinknctu/OmniUI
[4]: https://rvm.io/rvm/install
[5]: https://github.com/json-c/json-c
[6]: https://github.com/trema/trema-edge
