# Loki简单使用

![iC-Blog-headers-2-1024x224.png](https://i.loli.net/2020/09/04/F6VprQh57EinU2m.png)
> 说明：本文章是部署在虚拟机环境下,用来收集虚拟机环境下的日志  

参考文档：  
https://sbcode.net/grafana/install-promtail-service/  
https://github.com/grafana/loki/blob/v1.5.0/docs/getting-started/labels.md  
https://github.com/grafana/loki/blob/master/docs/logql.md#filter-expression  
https://github.com/grafana/loki/blob/master/docs/operations/storage/table-manager.md  
https://grafana.com/grafana/download  
https://github.com/grafana/loki/blob/master/docs/sources/clients/promtail/configuration.md#example-static-config-without-targets  
https://github.com/bmatcuk/doublestar

- Loki三大组件
  - **promtail**：日志收集客户端。个人理解（类似zabbix的agent,监控哪台机器就在哪台机器上部署）k8s环境下就使用DaemonSet方式运行在各个节点上。
  - **Loki**：日志收集服务端。接收来自`promtail`发送的日志。
  - **Grafana**: 日志展示

- 安装grafana
```
wget https://dl.grafana.com/oss/release/grafana-7.1.0-1.x86_64.rpm
sudo yum install grafana-7.1.0-1.x86_64.rpm
```
- 安装loki  
[loki.sh](https://github.com/happinesslijian/Happiness-blog/blob/master/%E5%8D%9A%E5%AE%A2%E6%96%87%E7%AB%A0/PLG/loki.sh)

- 安装promtail  
[promtail.sh](https://github.com/happinesslijian/Happiness-blog/blob/master/%E5%8D%9A%E5%AE%A2%E6%96%87%E7%AB%A0/PLG/promtail.sh)

参数介绍：  
- /etc/promtail/promtail-local-config.yaml
  - [配置参数说明](https://github.com/grafana/loki/blob/v1.5.0/docs/clients/promtail/configuration.md#configuring-promtail)
```
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

# 链接loki服务端的参数
clients:
  - url: http://${IP}:3100/loki/api/v1/push

scrape_configs:
# 监控哪些文件
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*log

# 拓展一下
# 假如你安装了supervisor并且要收集日志,如下：
- job_name: supervisor
  static_configs:
  - targets:
      - localhost
    labels:
      job: supervisor-logs
      __path__: /var/log/supervisor/*.log


# 如下写法会收集该目录下所有子目录中所有的(类似filebeat 穿透子目录查找日志文件,并索引)递归查询

参考链接 https://github.com/bmatcuk/doublestar#patterns

- job_name: 10.20.80.207
  static_configs:
  - targets:
      - localhost
    labels:
      job: NFS-logs
      __path__: /var/log/{,*/}{*[._]log,{mail,news}.{err,info,warn}}

# 递归查询可以查询到子目录中的日志,但是/var/log/目录下就查询不到了,比如：messages查询不到,所以要手动指定,如下：

- job_name: 10.20.80.207
  static_configs:
  - targets:
      - localhost
    labels:
      job: NFS-messages-logs
      __path__: /var/log/messages
```
- /etc/loki/loki-local-config.yaml
  - [配置参数说明](https://github.com/grafana/loki/blob/v1.5.0/docs/configuration/README.md#storage_config)
```
auth_enabled: false

# HTTP服务器监听端口
server:
  http_listen_port: 3100

ingester:
# 配置ingester的生命周期如何运行
# 以及它将在哪里注册以进行发现
  lifecycler:
    address: 127.0.0.1
# ring用于发现并连接到Ingesters
    ring:
# 用于连接后端存储,支持的值有：consul etcd inmemory
      kvstore:
        store: inmemory
# 写入和读取的指数
      replication_factor: 1
    final_sleep: 0s
# 空闲时间
  chunk_idle_period: 5m
# 保留时间
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
# BoltDB索引文件的位置
    directory: /tmp/loki/index

  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
# 是否保留数据
  retention_deletes_enabled: false
# 保留多久的数据
  retention_period: 0s
```
查询语句
```
{job="varlogs"}                     #匹配job=varlogs
{job=~"varlogs|etcd"}               #匹配job=varlogs和job=etcd
{filename="/var/log/xx.log"}        #按文件名匹配
{job="varlogs"} |= "192.168.0.100"  #匹配192.168.0.100机器的job=varlogs
{env="dev"}                         #多个索引都有env=dev等同于job=varlogs和job=etcd
```

# k8s环境下部署,我使用helm部署工具来部署

添加chart仓库
```
helm repo add loki https://grafana.github.io/loki/charts
helm repo add stable https://kubernetes-charts.storage.googleapis.com
```
更新chart仓库
```
helm repo update
```

- 部署loki   
修改loki配置文件
根据实际环境部署
```
helm pull loki/loki --untar
# 编辑如下，需要提前准备一个sc名为loki
vim loki/values.yaml



image:
  repository: grafana/loki
  tag: 1.6.0
  pullPolicy: IfNotPresent

  ## Optionally specify an array of imagePullSecrets.
  ## Secrets must be manually created in the namespace.
  ## ref: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
  ##
  # pullSecrets:
  #   - myRegistryKeySecretName

ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: chart-example.local
      paths: []
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

## Affinity for pod assignment
## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#affinity-and-anti-affinity
affinity: {}
# podAntiAffinity:
#   requiredDuringSchedulingIgnoredDuringExecution:
#   - labelSelector:
#       matchExpressions:
#       - key: app
#         operator: In
#         values:
#         - loki
#     topologyKey: "kubernetes.io/hostname"

## StatefulSet annotations
annotations: {}

# enable tracing for debug, need install jaeger and specify right jaeger_agent_host
tracing:
  jaegerAgentHost:

config:
  auth_enabled: true
  ingester:
    chunk_idle_period: 3m
    chunk_block_size: 262144
    chunk_retain_period: 1m
    max_transfer_retries: 0
    lifecycler:
      ring:
        kvstore:
          store: inmemory
        replication_factor: 1

      ## Different ring configs can be used. E.g. Consul
      # ring:
      #   store: consul
      #   replication_factor: 1
      #   consul:
      #     host: "consul:8500"
      #     prefix: ""
      #     http_client_timeout: "20s"
      #     consistent_reads: true
  limits_config:
    enforce_metric_name: false
    reject_old_samples: true
    reject_old_samples_max_age: 168h
  schema_config:
    configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v9
      index:
        prefix: index_
        period: 168h
  server:
    http_listen_port: 3100
  storage_config:
    boltdb:
      directory: /data/loki/index
    filesystem:
      directory: /data/loki/chunks
  chunk_store_config:
    max_look_back_period: 0s
  table_manager:
    retention_deletes_enabled: false
    retention_period: 0s

## Additional Loki container arguments, e.g. log level (debug, info, warn, error)
extraArgs: {}
  # log.level: debug

livenessProbe:
  httpGet:
    path: /ready
    port: http-metrics
  initialDelaySeconds: 45

## ref: https://kubernetes.io/docs/concepts/services-networking/network-policies/
networkPolicy:
  enabled: false

## The app name of loki clients
client: {}
  # name:

## ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
nodeSelector: {}

## ref: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
## If you set enabled as "True", you need :
## - create a pv which above 10Gi and has same namespace with loki
## - keep storageClassName same with below setting
persistence:
  enabled: true
  storageClassName: loki
  accessModes:
  - ReadWriteOnce
  size: 10Gi
  annotations: {}
  # subPath: ""
  # existingClaim:

## Pod Labels
podLabels: {}

## Pod Annotations
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "http-metrics"

podManagementPolicy: OrderedReady

## Assign a PriorityClassName to pods if set
# priorityClassName:

rbac:
  create: true
  pspEnabled: true

readinessProbe:
  httpGet:
    path: /ready
    port: http-metrics
  initialDelaySeconds: 45

replicas: 1

resources: {}
# limits:
#   cpu: 200m
#   memory: 256Mi
# requests:
#   cpu: 100m
#   memory: 128Mi

securityContext:
  fsGroup: 10001
  runAsGroup: 10001
  runAsNonRoot: true
  runAsUser: 10001

service:
  type: ClusterIP
  nodePort:
  port: 3100
  annotations: {}
  labels: {}

serviceAccount:
  create: true
  name:
  annotations: {}

terminationGracePeriodSeconds: 4800

## Tolerations for pod assignment
## ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
tolerations: []

# The values to set in the PodDisruptionBudget spec
# If not set then a PodDisruptionBudget will not be created
podDisruptionBudget: {}
# minAvailable: 1
# maxUnavailable: 1

updateStrategy:
  type: RollingUpdate

serviceMonitor:
  enabled: false
  interval: ""
  additionalLabels: {}
  annotations: {}
  # scrapeTimeout: 10s

initContainers: []
## Init containers to be added to the loki pod.
# - name: my-init-container
#   image: busybox:latest
#   command: ['sh', '-c', 'echo hello']

extraContainers: []
## Additional containers to be added to the loki pod.
# - name: reverse-proxy
#   image: angelbarrera92/basic-auth-reverse-proxy:dev
#   args:
#     - "serve"
#     - "--upstream=http://localhost:3100"
#     - "--auth-config=/etc/reverse-proxy-conf/authn.yaml"
#   ports:
#     - name: http
#       containerPort: 11811
#       protocol: TCP
#   volumeMounts:
#     - name: reverse-proxy-auth-config
#       mountPath: /etc/reverse-proxy-conf


extraVolumes: []
## Additional volumes to the loki pod.
# - name: reverse-proxy-auth-config
#   secret:
#     secretName: reverse-proxy-auth-config

## Extra volume mounts that will be added to the loki container
extraVolumeMounts: []

extraPorts: []
## Additional ports to the loki services. Useful to expose extra container ports.
# - port: 11811
#   protocol: TCP
#   name: http
#   targetPort: http

# Extra env variables to pass to the loki container
env: []
```
```
helm install loki -f values.yaml . -n loki
```
或者使用set
```
# 需要提前准备一个sc名为loki
helm install loki loki/loki --set persistence.storageClassName=loki -n loki
```


- 部署promtail
```
helm install promtail loki/promtail --set "loki.serviceName=loki" -n loki
```

- 部署grafana
```
# 需要提前准备一个sc名为grafana

helm install grafana stable/grafana --set "service.type=NodePort","ingress.enabled=true","ingress.hosts[0]=test.k8s.fit","persistence.enabled=true","persistence.storageClassName=grafana" -n loki
```

- 获取grafana UI密码
```
kubectl get secret -n loki grafana -o yaml

apiVersion: v1
data:
  admin-password: QTZwc1AzQnJjeVNtS0NFVjF0cW13MENoMUJNR0ZhNzJCWDI2YnUzNQ==
  admin-user: YWRtaW4=
  ldap-toml: ""
kind: Secret
metadata:
  creationTimestamp: "2020-08-20T09:03:19Z"
  labels:
    app.kubernetes.io/instance: grafana
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: grafana
    app.kubernetes.io/version: 6.7.1
    helm.sh/chart: grafana-5.0.10
  name: grafana
  namespace: loki
  resourceVersion: "27451687"
  selfLink: /api/v1/namespaces/loki/secrets/grafana
  uid: 7550707a-70c9-407d-ace1-9f10e6bd1040
type: Opaque


echo QTZwc1AzQnJjeVNtS0NFVjF0cW13MENoMUJNR0ZhNzJCWDI2YnUzNQ== | base64 -d

# 进入UI后记得改密码,默认随机密码是base64

# 或者
kubectl get secret grafana -n loki -o yaml | grep admin-password | awk '{print $2}' | base64 -d 
# 或者
kubectl get secret -n loki grafana -o jsonpath="{.data.admin-password}" | base64 -d
```
## dashboard配置
![微信截图_20200826174853.png](https://i.loli.net/2020/08/26/5RXA2Ct1oLeJVGS.png)

