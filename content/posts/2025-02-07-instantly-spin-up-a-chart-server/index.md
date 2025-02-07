---
title: Instantly Spin Up a Chart Server
category: memo
slug: instantly-spin-up-a-chart-server
date: 2025-02-07
---

## Why

Sometimes, you need a quick and temporary way to serve Helm charts without
setting up a full-fledged chart repository like
[ChartMuseum](https://chartmuseum.com/) or relying on an external service.
Whether you're testing a chart, sharing it within your local network, or
running an ad-hoc deployment, a simple and lightweight solution can save time.
This guide shows how to instantly spin up a Helm chart server using basic tools
like Git, Helm, and Python.

## How

### Setting Up the Chart Server

On the machine where you want to serve the chart:

```shell
# Clone the chart repository
git clone <chart-repository>
cd <chart-repository>

# Package the Helm chart
mkdir serv
helm package . -d serv
helm repo index serv

# Start a simple HTTP server
python -m http.server -d serv -b 0.0.0.0
```

This approach:

-  Packages the chart into a `.tgz` file
-  Generates an `index.yaml` for Helm to recognize the repository
-  Uses Python’s built-in HTTP server to serve the charts over HTTP

### Accessing the Chart Repository

On the client machine:

```shell
helm repo add <repo-name> http://<chart-server-ip>:8000
helm repo update <repo-name>
```

Once added, you can install charts from this temporary repository as usual:

```shell
helm install <release-name> <repo-name>/<chart-name>
```

## Wrapping up

This method quickly serves Helm charts without additional dependencies. It’s
ideal for local testing, CI/CD workflows, or small teams needing a temporary
chart server. For production use, consider more robust solutions like
ChartMuseum or an OCI-based Helm repository.

## References

-  [Helm Documentation](https://helm.sh/docs/)
-  [Python HTTP Server](https://docs.python.org/3/library/http.server.html)
