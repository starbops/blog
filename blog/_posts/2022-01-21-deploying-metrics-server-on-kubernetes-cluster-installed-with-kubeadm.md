---
layout: post
title: 'Deploying metrics-server on Kubernetes Cluster Installed with kubeadm'
category: memo
slug: deploying-metrics-server-on-kubernetes-cluster-installed-with-kubeadm
---
As you may have already known, I have a 4-node Kubernetes cluster, which was
installed using `kubeadm`. When I was trying to deploy metrics-server on my
cluster using the [official Helm
chart](https://artifacthub.io/packages/helm/metrics-server/metrics-server), I
got the following situation:

```bash
$ kubectl -n metrics-server get deploy
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
metrics-server   0/3     3            0           26h
$ kubectl -n metrics-server get po
NAME                              READY   STATUS    RESTARTS   AGE
metrics-server-59c9f76588-mnhst   0/1     Running   0          26h
metrics-server-59c9f76588-tf9fr   0/1     Running   0          26h
metrics-server-59c9f76588-zbwd4   0/1     Running   0          26h
```

In my deployment, there’re 3 replicas. Clearly, none of them are in ready state.
Pick one Pod and see what happened to the metrics-server application by
inspecting the log output:

```bash
$ kubectl -n metrics-server logs metrics-server-59c9f76588-mnhst
...
E0114 02:25:00.528571       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.88.114:10250/stats/summary?only_cpu_and_memory=true\": x509: certificate has
 expired or is not yet valid: current time 2022-01-14T02:25:00Z is after 2022-01-06T06:23:35Z" node="k8s-worker-3.internal.zespre.com"
E0114 02:25:00.528999       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.88.111:10250/stats/summary?only_cpu_and_memory=true\": x509: certificate has
 expired or is not yet valid: current time 2022-01-14T02:25:00Z is after 2021-11-20T07:36:02Z" node="k8s-master.internal.zespre.com"
E0114 02:25:00.537740       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.88.113:10250/stats/summary?only_cpu_and_memory=true\": x509: certificate has
 expired or is not yet valid: current time 2022-01-14T02:25:00Z is after 2021-11-20T07:36:02Z" node="k8s-worker-2.internal.zespre.com"
E0114 02:25:00.543400       1 scraper.go:139] "Failed to scrape node" err="Get \"https://192.168.88.112:10250/stats/summary?only_cpu_and_memory=true\": x509: certificate has
 expired or is not yet valid: current time 2022-01-14T02:25:00Z is after 2021-11-20T07:36:02Z" node="k8s-worker-1.internal.zespre.com"
I0114 02:25:01.372652       1 server.go:188] "Failed probe" probe="metric-storage-ready" err="not metrics to serve"
```

What the logs shown intrigued me, especially the “certificate expired” part. If
I remember correctly, the Kubernetes control plane uses a set of keys and
certificates for authentication over TLS for security reasons. The cluster was
installed with `kubeadm`. By default, the certificates required are
automatically generated and being valid for one year long. I went to the master
node and checked whether they’re expired or not.

```bash
$ sudo kubeadm certs check-expiration
[check-expiration] Reading configuration from the cluster...
[check-expiration] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Mar 23, 2022 02:44 UTC   67d                                     no
apiserver                  Mar 23, 2022 02:42 UTC   67d             ca                      no
apiserver-etcd-client      Mar 23, 2022 02:42 UTC   67d             etcd-ca                 no
apiserver-kubelet-client   Mar 23, 2022 02:42 UTC   67d             ca                      no
controller-manager.conf    Mar 23, 2022 02:43 UTC   67d                                     no
etcd-healthcheck-client    Mar 23, 2022 02:42 UTC   67d             etcd-ca                 no
etcd-peer                  Mar 23, 2022 02:42 UTC   67d             etcd-ca                 no
etcd-server                Mar 23, 2022 02:42 UTC   67d             etcd-ca                 no
front-proxy-client         Mar 23, 2022 02:42 UTC   67d             front-proxy-ca          no
scheduler.conf             Mar 23, 2022 02:43 UTC   67d                                     no

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Nov 18, 2030 09:01 UTC   8y              no
etcd-ca                 Nov 18, 2030 09:01 UTC   8y              no
front-proxy-ca          Nov 18, 2030 09:01 UTC   8y              no
```

Turns out that they’re still valid as of now. If you look closer, you’ll notice
that there’s no single certificate related to kubelet, which means we’re in the
wrong place for the answer (actually there’s a certificate called
“apiserver-kubelet-client” shown in the list, but it’s a **client auth**
certificate for apiserver to connect to kubelet, which is not in our
interest). So the next step is to check the configuration of kubelet daemons
running on all nodes including master node.

```bash
$ ps -ef | grep kubelet
root      5688     1  5  2021 ?        2-03:25:39 /usr/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --network-plugin=cni --pod-infra-container-image=k8s.gcr.io/pause:3.2
```

According to the official document, while installing the cluster with `kubeadm`,
the kubelet daemon uses a bootstrap token to do authentication and request a
client certificate from the API server. After the certificate request is
approved, the kubelet daemon retrieves the certificate and put it under
`/var/lib/kubelet/pki` (configurable via `--cert-dir` as an option of kubelet).

```bash
$ sudo cat /etc/kubernetes/kubelet.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <redacted>
    server: https://192.168.88.111:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    namespace: default
    user: default-auth
  name: default-context
current-context: default-context
kind: Config
preferences: {}
users:
- name: default-auth
  user:
    client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
    client-key: /var/lib/kubelet/pki/kubelet-client-current.pem
$ ls -l /var/lib/kubelet/pki/
total 16
-rw------- 1 root root 1143 Nov 20  2020 kubelet-client-2020-11-20-17-12-03.pem
-rw------- 1 root root 1147 Aug 27 15:01 kubelet-client-2021-08-27-15-01-25.pem
lrwxrwxrwx 1 root root   59 Aug 27 15:01 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2021-08-27-15-01-25.pem
-rw-r--r-- 1 root root 2417 Nov 20  2020 kubelet.crt
-rw------- 1 root root 1675 Nov 20  2020 kubelet.key
```

As you can see, the certificate and key are encoded in
`kubelet-client-current.pem` and are renewed periodically. However, this
certificate provided by TLS bootstrapping is signed for **client auth** only,
and thus cannot be used as serving certificates, or **server auth**. Try to
examine the certificate by `openssl` tool:

```bash
$ sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem \
>    -noout -subject -issuer -dates -ext extendedKeyUsage
subject=O = system:nodes, CN = system:node:k8s-worker-1.internal.zespre.com
issuer=CN = kubernetes
notBefore=Aug 27 06:56:24 2021 GMT
notAfter=Aug 27 06:56:24 2022 GMT
X509v3 Extended Key Usage:
    TLS Web Client Authentication
```

At the same time, we could inspect the serving certificate from the kubelet API
endpoint shown in the metrics-server logs for comparison:

```bash
$ echo | \
> openssl s_client -connect k8s-worker-1.internal.zespre.com:10250 2>/dev/null | \
> openssl x509 -noout -subject -issuer -dates -ext extendedKeyUsage
subject=CN = k8s-worker-1.internal.zespre.com@1605861362
issuer=CN = k8s-worker-1.internal.zespre.com-ca@1605861362
notBefore=Nov 20 07:36:02 2020 GMT
notAfter=Nov 20 07:36:02 2021 GMT
X509v3 Extended Key Usage:
    TLS Web Server Authentication
```

The serving certificate is not the same as the one under `/var/lib/kubelet/pki`
as their dates of issuance and expiration are different. So, again, we’re on the
wrong place. But I have a strong feeling that we’re close to the answer. I then
noticed there’s a `kubelet.crt` and `kubelet.key` under `/var/lib/kubelet/pki`
directory. I checked the certificate using `openssl` again out of curiosity:

```bash
$ sudo openssl x509 -in /var/lib/kubelet/pki/kubelet.crt \
>    -noout -subject -issuer -dates -ext extendedKeyUsage
subject=CN = k8s-worker-1.internal.zespre.com@1605861362
issuer=CN = k8s-worker-1.internal.zespre.com-ca@1605861362
notBefore=Nov 20 07:36:02 2020 GMT
notAfter=Nov 20 07:36:02 2021 GMT
X509v3 Extended Key Usage:
    TLS Web Server Authentication
```

This is the exact certificate that kubelet API is serving! It’s worth mentioning
that this is a self-signed certificate. It is generated during the installation
of kubelet. If I had deployed metrics-server earlier within the certification’s
expiration date, I’ll be encounter with another issue related to validation of
self-signed certificate which is often solved by running metrics-server with
`--kubelet-insecure-tls`. But it’s definitely not what I want to see. To
summarize, there’re two types of certificate under `/var/lib/kubelet/pki`:

-  Client certificate, which is for kubelet to initiate connections to apiserver,
   and is auto-rotated by kubelet by default.
-  Server certificate, which is serving with kubelet’s own API, and is **not**
   auto-rotated by kubelet by default.

## Serving Certificates Signed by Cluster CA

After doing some research, it is quite simple to solve this issue. The main idea
is to make the serving certificate of kubelet signed by cluster certificate
authority (CA), and it’s better to have an auto-rotate mechanism. Two steps are
required:

1. Adding `serverTLSBootstrap: true` in cluster’s kubelet ConfigMap
   `kubelet-config`.
1. Adding `serverTLSBootstrap: true` into `config.yaml` under
   `/var/lib/kubelet/` on all cluster nodes.

```bash
$ kubectl -n kube-system describe cm kubelet-config-1.20
Name:         kubelet-config-1.20
Namespace:    kube-system
Labels:       <none>
Annotations:  kubeadm.kubernetes.io/component-config.hash: sha256:306a726156f1e2879bedabbdfa452caae8a63929426a55de71c22fe901fde977

Data
====
kubelet:
----
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: cgroupfs
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
resolvConf: /run/systemd/resolve/resolv.conf
rotateCertificates: true
runtimeRequestTimeout: 0s
serverTLSBootstrap: true
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s

Events:  <none>
```

Why this configuration matters? According to the official documentation:

> serverTLSBootstrap enables server certificate bootstrap. Instead of self
> signing a serving certificate, the Kubelet will request a certificate from the
> '[certificates.k8s.io](http://certificates.k8s.io/)' API. This requires an
> approver to approve the certificate signing requests (CSR).

So to make the newly added configuration to work, we need to restart kubelet
daemon on all nodes:

```bash
sudo systemctl restart kubelet.service
```

Then we can check if there’s any CSR created:

```bash
$ kubectl get csr
NAME        AGE   SIGNERNAME                      REQUESTOR                                      CONDITION
csr-9czkl   14s   kubernetes.io/kubelet-serving   system:node:k8s-master.internal.zespre.com     Pending
csr-dl5hl   13s   kubernetes.io/kubelet-serving   system:node:k8s-worker-3.internal.zespre.com   Pending
csr-w6pck   18s   kubernetes.io/kubelet-serving   system:node:k8s-worker-2.internal.zespre.com   Pending
csr-xbwwt   19s   kubernetes.io/kubelet-serving   system:node:k8s-worker-1.internal.zespre.com   Pending
```

Since I have 4 nodes, I got 4 CSRs to be approved.

```bash
$ kubectl certificate approve csr-9czkl
certificatesigningrequest.certificates.k8s.io/csr-9czkl approved
$ kubectl certificate approve csr-dl5hl
certificatesigningrequest.certificates.k8s.io/csr-dl5hl approved
$ kubectl certificate approve csr-xbwwt
certificatesigningrequest.certificates.k8s.io/csr-xbwwt approved
$ kubectl certificate approve csr-w6pck
certificatesigningrequest.certificates.k8s.io/csr-w6pck approved
$ kubectl get csr
NAME        AGE    SIGNERNAME                      REQUESTOR                                      CONDITION
csr-9czkl   3m2s   kubernetes.io/kubelet-serving   system:node:k8s-master.internal.zespre.com     Approved,Issued
csr-dl5hl   3m1s   kubernetes.io/kubelet-serving   system:node:k8s-worker-3.internal.zespre.com   Approved,Issued
csr-w6pck   3m6s   kubernetes.io/kubelet-serving   system:node:k8s-worker-2.internal.zespre.com   Approved,Issued
csr-xbwwt   3m7s   kubernetes.io/kubelet-serving   system:node:k8s-worker-1.internal.zespre.com   Approved,Issued
```

After all the CSRs are approved, go check the PKI directory on each node to see
if there’s any serving certificate.

```bash
$ ls -l /var/lib/kubelet/pki/
total 20
-rw------- 1 root root 1143 Nov 20  2020 kubelet-client-2020-11-20-17-12-03.pem
-rw------- 1 root root 1147 Aug 27 15:01 kubelet-client-2021-08-27-15-01-25.pem
lrwxrwxrwx 1 root root   59 Aug 27 15:01 kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2021-08-27-15-01-25.pem
-rw-r--r-- 1 root root 2417 Nov 20  2020 kubelet.crt
-rw------- 1 root root 1675 Nov 20  2020 kubelet.key
-rw------- 1 root root 1216 Jan 14 13:40 kubelet-server-2022-01-14-13-40-10.pem
lrwxrwxrwx 1 root root   59 Jan 14 13:40 kubelet-server-current.pem -> /var/lib/kubelet/pki/kubelet-server-2022-01-14-13-40-10.pem
```

Now we got serving certificates signed by cluster CA for kubelet APIs. And due
to the feature gate `RotateKubeletServerCertificate`, which is turned on by
default, kubelet will keep the serving certificate valid (just to remember to
approve the CSRs).

## Verification

It’s time to go back to our metrics-server!

```bash
$ kubectl top nodes
NAME                               CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
k8s-master.internal.zespre.com     241m         6%     1666Mi          43%
k8s-worker-1.internal.zespre.com   328m         8%     1449Mi          37%
k8s-worker-2.internal.zespre.com   121m         3%     1692Mi          44%
k8s-worker-3.internal.zespre.com   201m         5%     2730Mi          34%
$ kubectl top pods
NAME                         CPU(cores)   MEMORY(bytes)
dnsutils                     0m           0Mi
hello-k8s-75d8c7c996-492kx   1m           9Mi
hello-k8s-75d8c7c996-9v6br   1m           9Mi
hello-k8s-75d8c7c996-x6x7r   1m           6Mi
```

Things are back to normal.

## References

-  [https://github.com/kubernetes/kubeadm/issues/2186](https://github.com/kubernetes/kubeadm/issues/2186)
-  [TLS
   bootstrapping](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/#client-and-serving-certificates)
-  [Kubelet Configuration
   (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)
-  [Make metrics-server work out of the box with
   kubeadm](https://particule.io/en/blog/kubeadm-metrics-server/)
