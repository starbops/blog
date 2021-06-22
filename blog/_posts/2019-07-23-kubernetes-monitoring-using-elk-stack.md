---
layout: post
title: 'Kubernetes Monitoring Using ELK Stack'
category: memo
slug: kubernetes-monitoring-using-elk-stack
---
## Elasticsearch

```bash
curl -L -O <https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.2.0-linux-x86_64.tar.gz>
tar -xzvf elasticsearch-7.2.0-linux-x86_64.tar.gz
cd elasticsearch-7.2.0
```

`config/elasticsearch.yml`

```yaml
network.host: 0.0.0.0
cluster.initial_master_nodes: ["172.16.169.17"]
```

```bash
sudo sysctl -w vm.max_map_count=262144
```

```bash
./bin/elasticsearch
```

## Kibana

```bash
curl -L -O <https://artifacts.elastic.co/downloads/kibana/kibana-7.2.0-linux-x86_64.tar.gz>
tar xzvf kibana-7.2.0-linux-x86_64.tar.gz
cd kibana-7.2.0-linux-x86_64/
```

`config/kibana.yml`

```yaml
server.host: "0.0.0.0"
```

```bash
./bin/kibana
```

## Beats

Edit `ELASTICSEARCH_HOSTS`:

```text
["<http://172.16.169.17:9200>"]
```

### Filebeat

`filebeat-kubernetes.yaml`:

```yaml
- condition.contains:
    kubernetes.labels.app: redis
  config:
    - module: redis
      log:
        input:
          type: docker
          containers.ids:
            - ${data.kubernetes.container.id}
      slowlog:
        enabled: true
        var.hosts: ["${data.host}:${data.port}"]
```

```bash
kubectl create -f filebeat-kubernetes.yaml
kubectl get pods -n kube-system -l k8s-app=filebeat-dynamic
```

### Metricbeat

`metricbeat-kubernetes.yaml`:

```yaml
- condition.equals:
    kubernetes.labels.tier: backend
  config:
    - module: redis
      metricsets: ["info", "keyspace"]
      period: 10s

      # Redis hosts
      hosts: ["${data.host}:${data.port}"]
```

```bash
kubectl create -f metricbeat-kubernetes.yaml
kubectl get pods -n kube-system -l k8s-app=metricbeat
```

### Packetbeat

`packetbeat-kubernetes.yaml`:

```yaml
packetbeat.interfaces.device: any

packetbeat.protocols:
- type: dns
  ports: [53]
  include_authorities: true
  include_additionals: true

- type: http
  ports: [80, 8000, 8080, 9200]

- type: mysql
  ports: [3306]

- type: redis
  ports: [6379]

packetbeat.flows:
  timeout: 30s
  period: 10s
```

```bash
kubectl create -f packetbeat-kubernetes.yaml
kubectl get pods -n kube-system -l k8s-app=packetbeat-dynamic
```

## References

-  [Getting started with the Elastic Stack](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-elastic-stack.html)
-  [Example: Add logging and metrics to the PHP / Redis Guestbook example](https://kubernetes.io/docs/tutorials/stateless-application/guestbook-logs-metrics-with-elk/)
