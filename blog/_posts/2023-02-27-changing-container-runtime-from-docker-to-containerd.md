---
layout: post
title: 'Changing Container Runtime from Docker to containerd'
category: note
slug: changing-container-runtime-from-docker-to-containerd
---

The `dockershim` has been announced as deprecated since Kubernetes v1.20. And
Kubernetes v1.23 is about to step into its EOL after the end of this month. So
it’s time to move forward! Let’s upgrade the cluster to v1.24. This article is
solely for the personal record about changing container runtimes to upgrade
Kubernetes from v1.23 to v1.24.

## Prerequisites

Firstly, make sure what container runtime you are using:

```bash
$ kubectl get nodes -o wide
NAME                               STATUS   ROLES                  AGE     VERSION    INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master.internal.zespre.com     Ready    control-plane,master   2y97d   v1.23.15   192.168.88.111   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
k8s-worker-1.internal.zespre.com   Ready    <none>                 2y97d   v1.23.15   192.168.88.112   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
k8s-worker-2.internal.zespre.com   Ready    <none>                 2y97d   v1.23.15   192.168.88.113   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
k8s-worker-3.internal.zespre.com   Ready    <none>                 2y50d   v1.23.15   192.168.88.114   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
```

For my environment, it is `docker://20.10.7`. So it’s a must to change to other
CRI-compliant container runtimes.

Drain the node that you want to work on:

```bash
kubelet drain <node> --ignore-daemonsets --delete-emptydir-data
```

Stop the `kubelet` and `docker` on the node:

```bash
sudo systemctl stop kubelet.service
sudo systemctl disable docker.service --now
```

## Installation

### containerd

Install `containerd` binaries and their corresponding service file:

```bash
$ wget https://github.com/containerd/containerd/releases/download/v1.6.18/containerd-1.6.18-linux-amd64.tar.gz
$ sudo tar -zxvf containerd-1.6.18-linux-amd64.tar.gz -C /usr/local
$ sudo mkdir -p /usr/local/lib/systemd/system/
$ sudo curl -sfL https://raw.githubusercontent.com/containerd/containerd/main/containerd.service \
    -o /usr/local/lib/systemd/system/containerd.service
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable containerd.service --now
```

### runc

```bash
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

### CNI

```bash
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
sudo mv /opt/cni/bin /opt/cni/bin.bak
sudo mkdir -p /opt/cni/bin
sudo tar -zxvf cni-plugins-linux-amd64-v1.2.0.tgz -C /opt/cni/bin
```

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd.service
```

## Configure kubelet to Use containerd

Basically, there are two places to modify if you provision the node with
`kubeadm` at the beginning:

1. The `/var/lib/kubelet/kubeadm-flags.env` file
1. The `kubeadm.alpha.kubernetes.io/cri-socket` annotation of the node

In `/var/lib/kubelet/kubeadm-flags.env`, append two flags to make `kubelet` use
`containerd` as the new container runtime:

1. `--container-runtime=remote`
1. `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`

```text
KUBELET_KUBEADM_ARGS="--network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.2 --container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
```

For the annotation in the node’s resource, a similar change can be done via

```bash
kubectl annotate node <node> kubeadm.alpha.kubernetes.io/cri-socket=unix:///run/containerd/containerd.sock --overwrite=true
```

Then we’re ready to start the `kubelet` again with the new container runtime!

```bash
sudo systemctl start kubelet.service
```

After a while, you should see the container runtime of the target node becomes
something like `containerd-1.6.18`:

```bash
$ kubectl get nodes -o wide
NAME                               STATUS                     ROLES                  AGE     VERSION    INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
k8s-master.internal.zespre.com     Ready                      control-plane,master   2y98d   v1.23.15   192.168.88.111   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
k8s-worker-1.internal.zespre.com   Ready,SchedulingDisabled   <none>                 2y98d   v1.23.15   192.168.88.112   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   containerd://1.6.18
k8s-worker-2.internal.zespre.com   NotReady                   <none>                 2y98d   v1.23.15   192.168.88.113   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
k8s-worker-3.internal.zespre.com   Ready                      <none>                 2y51d   v1.23.15   192.168.88.114   <none>        Ubuntu 18.04.5 LTS   4.15.0-194-generic   docker://20.10.7
```

And you can uncordon the node:

```bash
kubectl uncordon <node>
```

Iterate these steps through all the nodes in the cluster.

1. Drain the node
1. Install containerd, runc, CNI binaries on the node
1. Configure kubelet with the new container runtime
1. Uncordon the node

## Cleanup

If things are going well, you can remove the old container runtime since it’s no
longer needed. In my case, it is the `[docker.io](http://docker.io)` package to
remove:

```bash
$ sudo apt purge docker.io
Reading package lists... Done
Building dependency tree
Reading state information... Done
The following packages were automatically installed and are no longer required:
  bridge-utils cgroupfs-mount containerd pigz runc ubuntu-fan
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  docker.io*
0 upgraded, 0 newly installed, 1 to remove and 70 not upgraded.
After this operation, 193 MB disk space will be freed.
Do you want to continue? [Y/n]
(Reading database ... 141670 files and directories currently installed.)
Removing docker.io (20.10.7-0ubuntu5~18.04.3) ...
'/usr/share/docker.io/contrib/nuke-graph-directory.sh' -> '/var/lib/docker/nuke-graph-directory.sh'
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
(Reading database ... 141464 files and directories currently installed.)
Purging configuration files for docker.io (20.10.7-0ubuntu5~18.04.3) ...
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend requires a screen at least 13 lines tall and 31 columns wide.)
debconf: falling back to frontend: Readline

Nuking /var/lib/docker ...
  (if this is wrong, press Ctrl+C NOW!)

+ sleep 10

+ rm -rf /var/lib/docker/builder /var/lib/docker/buildkit /var/lib/docker/containers /var/lib/docker/image /var/lib/docker/network /var/lib/docker/nuke-graph-directory.sh /var/lib/docker/overlay2 /var/lib/docker/plugins /var/lib/docker/runtimes /var/lib/docker/swarm /var/lib/docker/tmp /var/lib/docker/trust /var/lib/docker/volumes
dpkg: warning: while removing docker.io, directory '/etc/docker' not empty so not removed
```

## Post-configs

To make sure things won’t break after node reboots, we need to persist some
configurations currently effective on the system. Please do the following steps
on every node if there’s no similar setup existed.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```

## Troubleshooting

### PLEG is not healthy

When doing the work on the first node, I noticed that the second worker node
became unready even though I didn’t drain the node. And the reason for the
unready state is shown below:

```bash
Ready                Unknown   Mon, 27 Feb 2023 13:55:37 +0800   Mon, 27 Feb 2023 13:54:29 +0800   NodeStatusUnknown   [container runtime is down, PLEG is not healthy: pleg was
ast seen active 7m27.961229215s ago; threshold is 3m0s[]
```

The load is extremely high on the worker node:

```bash
$ uptime
 14:56:34 up 135 days,  2:36,  1 user,  load average: 190.44, 174.46, 169.43
```

## References

-  [Find Out What Container Runtime is Used on a
   Node](https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/find-out-runtime-you-use/)
-  [Changing the Container Runtime on a Node from Docker Engine to
   containerd](https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/)
-  [containerd/getting-started.md at main ·
   containerd/containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
