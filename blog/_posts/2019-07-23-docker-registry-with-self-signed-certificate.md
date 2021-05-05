---
layout: post
title: 'Docker Registry with Self-Signed Certificate'
category: memo
slug: docker-registry-with-self-signed-certificate
---
```bash
$ mkdir certs
$ openssl req \
		-newkey rsa:4096 
		-nodes \
		-sha256 \
		-keyout certs/domain.key \
		-x509 \
		-days 365 \
		-out certs/domain.crt
```

```bash
$ docker secret create domain.crt certs/domain.crt
$ docker secret create domain.key certs/domain.key
$ docker secret ls
ID                          NAME                DRIVER              CREATED             UPDATED
108vdrp0wpa7sl2b99gvqp2gd   domain.crt                              4 days ago          4 days ago
rjx8c7h8j0k2yb19dxae25nji   domain.key                              4 days ago          4 days ago
```

```bash
$ docker service create --name registry \
		--secret domain.crt \
		--secret domain.key \
		--constraint 'node.labels.registry==true' \
		--mount type=bind,src=/mnt/registry,dst=/var/lib/registry \
		-e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
		-e REGISTRY_HTTP_TLS_CERTIFICATE=/run/secrets/domain.crt \
		-e REGISTRY_HTTP_TLS_KEY=/run/secrets/domain.key \
		--publish published=443,target=443 \
		--replicas 1 registry:2
```

On all Docker daemon, do the following:

```bash
$ sudo mv domain.crt /etc/docker/certs.d/registry.bampi.net/ca.crt
$ sudo chown root.root /etc/docker/certs.d/registry.bampi.net/ca.crt
$ sudo systemctl restart docker.service
```

If you have pure Docker client environment, please also trust the certificate at the OS level. Following will use CentOS 6.9 as example:

```bash
$ sudo cp certs/domain.crt /etc/pki/ca-trust/source/anchors/myregistrydomain.com.crt
$ sudo update-ca-trust
```

## References

- [Test an insecure registry](https://docs.docker.com/registry/insecure/)
- [Deploy a registry server](https://docs.docker.com/registry/deploying/#get-a-certificate)
- [Manage sensitive data with Docker secrets](https://docs.docker.com/v17.12/engine/swarm/secrets/#about-secrets)
- [How to setup a private docker registry with a self sign certificate](https://medium.com/@ifeanyiigili/how-to-setup-a-private-docker-registry-with-a-self-sign-certificate-43a7407a1613)
