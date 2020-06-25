# 一个web编程界面送给爱写代码的你

![](https://imgkr.cn-bj.ufileos.com/77f16a45-315d-4b20-93fd-37b499e2e777.jpg)

背景：最近一直在研究jupyter相关的知识,jupyterhub jupyterlab jupyternotebooks等,经过不断的努(踩)力(坑)以及数十根头发的代价,终于把jupyterhub成功部署在k8s里了！本篇文章内,只讲述了如何把jupyterhub部署在k8s里,包括配置文件的讲解(不包括docker环境下,docker环境下,详见下篇文章)废话不多说,直接来干货！

|集群环境|集群版本|搭建方式|helm版本|
|:--:|:--:|:--:|:--:|
|master|v1.16.8|kubeadm|v3.1.1|
|node1|v1.16.8|kubeadm|v3.1.1|
|node2|v1.16.8|kubeadm|v3.1.1|

### 安装helm
```
wget https://get.helm.sh/helm-v3.1.1-linux-amd64.tar.gz
tar xf helm-v3.1.1-linux-amd64.tar.gz
cp linux-amd64/helm /usr/local/bin/
helm version
```
- 添加jupyterhub的repo源并更新
```
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/

helm repo update
```
### 安装ldap
ldap可以安装在k8s内也可以安装在VM中,看你需求而定
我这里是把ldap安装到k8s中了,过程略！

### 安装nfs-client-provisioner
安装nfs-client-provisioner用来做动态存储,即web页面中写完的代码存储位置
安装nfs-client-provisioner过程略！

- 将jupyterhub相关配置拉取到本地进行编辑
```
helm pull jupyterhub/jupyterhub https://jupyterhub.github.io/helm-chart/ --untar && cd jupyterhub
```
### 更改配置文件
```
custom: {}

hub:
  service:
    type: ClusterIP
    annotations: {}
    ports:
      nodePort:
    loadBalancerIP:
  baseUrl: /
  cookieSecret:
  publicURL:
  initContainers: []
  uid: 1000
  fsGid: 1000
  nodeSelector: {}
  concurrentSpawnLimit: 64
  consecutiveFailureLimit: 5
  activeServerLimit:
  deploymentStrategy:
    ## type: Recreate
    ## - sqlite-pvc backed hubs require the Recreate deployment strategy as a
    ##   typical PVC storage can only be bound to one pod at the time.
    ## - JupyterHub isn't designed to support being run in parallell. More work
    ##   needs to be done in JupyterHub itself for a fully highly available (HA)
    ##   deployment of JupyterHub on k8s is to be possible.
    type: Recreate
  db:
    type: sqlite-pvc
    upgrade:
    pvc:
      annotations: {}
      selector: {}
      accessModes:
        - ReadWriteOnce
      storage: 1Gi
      subPath:
# 提前创建好的sc
      storageClassName: nfs-jupyterhub
    url:
    password:
  labels: {}
  annotations: {}
  extraConfig:
    jupyterlab: |
      c.Spawner.cmd = ['jupyter-labhub']
  extraConfigMap: {}
  extraEnv: {}
  extraContainers: []
  extraVolumes: []
  extraVolumeMounts: []
  image:
    name: jupyterhub/k8s-hub
    tag: '0.9.0'
    # pullSecrets:
    #   - secretName
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
  services: {}
  imagePullSecret:
    enabled: false
    registry:
    username:
    email:
    password:
  pdb:
    enabled: true
    minAvailable: 1
  networkPolicy:
    enabled: false
    ingress: []
    egress:
      - to:
          - ipBlock:
              cidr: 0.0.0.0/0
  allowNamedServers: false
  namedServerLimitPerUser:
  authenticatePrometheus:
  redirectToServer:
  shutdownOnLogout:
  templatePaths: []
  templateVars: {}
  livenessProbe:
    enabled: false
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    enabled: true
    initialDelaySeconds: 0
    periodSeconds: 50
  # existingSecret: existing-secret

rbac:
  enabled: true


proxy:
# 使用命令openssl rand -hex 32生成的十六进制字符串粘贴到下面
  secretToken: 'e734c6d0d526140a7de392cf67ec7bc990625be1e8502da672b829df8ef34e91'
  deploymentStrategy:
    ## type: Recreate
    ## - JupyterHub's interaction with the CHP proxy becomes a lot more robust
    ##   with this configuration. To understand this, consider that JupyterHub
    ##   during startup will interact a lot with the k8s service to reach a
    ##   ready proxy pod. If the hub pod during a helm upgrade is restarting
    ##   directly while the proxy pod is making a rolling upgrade, the hub pod
    ##   could end up running a sequence of interactions with the old proxy pod
    ##   and finishing up the sequence of interactions with the new proxy pod.
    ##   As CHP proxy pods carry individual state this is very error prone. One
    ##   outcome when not using Recreate as a strategy has been that user pods
    ##   have been deleted by the hub pod because it considered them unreachable
    ##   as it only configured the old proxy pod but not the new before trying
    ##   to reach them.
    type: Recreate
    ## rollingUpdate:
    ## - WARNING:
    ##   This is required to be set explicitly blank! Without it being
    ##   explicitly blank, k8s will let eventual old values under rollingUpdate
    ##   remain and then the Deployment becomes invalid and a helm upgrade would
    ##   fail with an error like this:
    ##
    ##     UPGRADE FAILED
    ##     Error: Deployment.apps "proxy" is invalid: spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy `type` is 'Recreate'
    ##     Error: UPGRADE FAILED: Deployment.apps "proxy" is invalid: spec.strategy.rollingUpdate: Forbidden: may not be specified when strategy `type` is 'Recreate'
    rollingUpdate:
  service:
    type: NodePort
    labels: {}
    annotations: {}
    nodePorts:
      http:
      https:
    loadBalancerIP:
    loadBalancerSourceRanges: []
  chp:
    image:
      name: jupyterhub/configurable-http-proxy
      tag: 4.2.1
    livenessProbe:
      enabled: true
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      enabled: true
      initialDelaySeconds: 0
      periodSeconds: 10
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
  traefik:
    image:
      name: traefik
      tag: v2.1
    hsts:
      maxAge: 15724800 # About 6 months
      includeSubdomains: false
    resources: {}
  secretSync:
    image:
      name: jupyterhub/k8s-secret-sync
      tag: '0.9.0'
    resources: {}
  labels: {}
  nodeSelector: {}
  pdb:
    enabled: true
    minAvailable: 1
  https:
    enabled: true
    type: letsencrypt
    #type: letsencrypt, manual, offload, secret
    letsencrypt:
      contactEmail: ''
      # Specify custom server here (https://acme-staging-v02.api.letsencrypt.org/directory) to hit staging LE
      acmeServer: ''
    manual:
      key:
      cert:
    secret:
      name: ''
      key: tls.key
      crt: tls.crt
    hosts: []
  networkPolicy:
    enabled: false
    ingress: []
    egress:
      - to:
          - ipBlock:
              cidr: 0.0.0.0/0


auth:
  type: ldap
  whitelist:
    users:
# 管理员用户（不利于管理建议不要使用 在这里创建了用户,ldap里是不会同步的,所以不建议使用）
  admin: 
    access: true
    users:
      - laoshi
  dummy:
    password:
# auth.ldap.server.address并且auth.ldap.dn.templates是必需的
  ldap:
    server: 
      address: 10.20.80.203
      port: 31712
    dn:
      templates:
        - 'uid={username},ou=AI,dc=lhws,dc=com'
#      search: {}
#      user: {}
    user: {}
  state:
    enabled: false
    cryptoKey:


singleuser:
  extraTolerations: []
  nodeSelector: {}
  extraNodeAffinity:
    required: []
    preferred: []
  extraPodAffinity:
    required: []
    preferred: []
  extraPodAntiAffinity:
    required: []
    preferred: []
  networkTools:
    image:
      name: jupyterhub/k8s-network-tools
      tag: '0.9.0'
  cloudMetadata:
    enabled: false
    ip: 169.254.169.254
  networkPolicy:
    enabled: false
    ingress: []
    egress:
    # Required egress is handled by other rules so it's safe to modify this
      - to:
          - ipBlock:
              cidr: 0.0.0.0/0
              except:
                - 169.254.169.254/32
  events: true
  extraAnnotations: {}
  extraLabels:
    hub.jupyter.org/network-access-hub: 'true'
  extraEnv: 
    EDITOR: "vim"
  lifecycleHooks:
# 我这里做了定制,将会在用户登陆到web界面后看到的目录
    postStart:
      exec:
        command:
          - "sh"
          - "-c"
          - >
            cp -r /code/ /home/jovyan;
            cp -r /dataset/ /home/jovyan;
            cp -r /test/ /home/jovyan;
            cp -r /train/ /home/jovyan
  initContainers: []
  extraContainers: []
  uid: 1000
  fsGid: 100
  serviceAccountName:
  storage:
    type: dynamic
    extraLabels: {}
    extraVolumes: []
    extraVolumeMounts: []
    static:
      pvcName:
      subPath: '{username}'
# 默认请求数据卷大小
    capacity: 10Gi
    homeMountPath: /home/jovyan
    dynamic:
# 提前创建好的sc
      storageClass: nfs-jupyterhub
      pvcNameTemplate: claim-{username}{servername}
      volumeNameTemplate: volume-{username}{servername}
      storageAccessModes: [ReadWriteOnce]
  image:
# 默认是jupyterhub/k8s-singleuser-sample我这里做了定制 下文会提到关于定制
    name: harbor.k8s.fit/jupyter/k8s-singleuser-sample
    tag: '1.0'
    pullPolicy: IfNotPresent
    # pullSecrets:
    #   - secretName
  imagePullSecret:
    enabled: false
    registry:
    username:
    email:
    password:
  startTimeout: 300
# 资源限制部分保证有0.5个cpu上限为0.5个cpu
  cpu:
    limit: .5
    guarantee: .5
# 资源限制部分保证有1G内存，上限为1G内存
  memory:
    limit: 1G
    guarantee: 1G
  extraResource:
    limits: {}
    guarantees: {}
  cmd: jupyterhub-singleuser
# 默认是/lab即jupyterlab 可以换成/tree即jupyternotebooks
  defaultUrl: "/lab"
  extraPodConfig: {}


scheduling:
  userScheduler:
    enabled: true
    replicas: 2
    logLevel: 4
    ## policy:
    ## Allows you to provide custom YAML/JSON to render into a JSON policy.cfg,
    ## a configuration file for the kube-scheduler binary.
    ## NOTE: The kube-scheduler binary in the kube-scheduler image we are
    ## currently using may be version bumped. It would for example happen if we
    ## increase the lowest supported k8s version for the helm chart. At this
    ## point, the provided policy.cfg may require a change along with that due
    ## to breaking changes in the kube-scheduler binary.
    policy: {}
    image:
      name: gcr.io/google_containers/kube-scheduler-amd64
      tag: v1.13.12
    nodeSelector: {}
    pdb:
      enabled: true
      minAvailable: 1
    resources:
      requests:
        cpu: 50m
        memory: 256Mi
  podPriority:
    enabled: false
    globalDefault: false
    defaultPriority: 0
    userPlaceholderPriority: -10
  userPlaceholder:
    enabled: true
    replicas: 0
  corePods:
    nodeAffinity:
      matchNodePurpose: prefer
  userPods:
    nodeAffinity:
      matchNodePurpose: prefer


prePuller:
  hook:
# 默认是true 将会在集群所有节点上pull该镜像
    enabled: false
    image:
      name: jupyterhub/k8s-image-awaiter
      tag: '0.9.0'
  continuous:
    enabled: true
  extraImages: {}
  pause:
    image:
      name: gcr.io/google_containers/pause
      tag: '3.1'

# ingress相关配置 我这里没有设置证书
# 前提是安装了 Ingress Controller 否则不会正常运行
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "nginx"
  hosts:
    - jupyterhub.lhws.com
  pathSuffix: ''
  tls: []


cull:
  enabled: true
  users: false
  removeNamedServers: false
  timeout: 3600
  every: 600
  concurrency: 10
  maxAge: 0


debug:
  enabled: false
```
### 部署jupyterhub
```
helm install jhub -f values.yaml . -n jhub

#假如配置文件有变动 对其更新命令如下

helm upgrade jhub -f values.yaml . -n jhub
```
### 默认会pull国外的源 手动把镜像pull到调度的节点并改tag
```
docker pull registry.aliyuncs.com/google_containers/pause:3.1 &&
docker pull registry.aliyuncs.com/google_containers/kube-scheduler:v1.13.12 &&
docker tag registry.aliyuncs.com/google_containers/pause:3.1 gcr.io/google_containers/pause:3.1 &&
docker tag registry.aliyuncs.com/google_containers/kube-scheduler:v1.13.12 gcr.io/google_containers/kube-scheduler-amd64:v1.13.12
```
### 验证
```
[root@master jupyterhub]# kubectl get pod,svc,ing -n jhub -o wide
NAME                                                        READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
pod/continuous-image-puller-cvwsx                           1/1     Running   0          126m    10.244.38.147   node1   <none>           <none>
pod/continuous-image-puller-lss88                           1/1     Running   0          126m    10.244.11.21    node2   <none>           <none>
pod/hub-589bc9bfb7-28wlx                                    1/1     Running   0          17m     10.244.38.151   node1   <none>           <none>
pod/jupyter-laoshi                                          1/1     Running   0          16m     10.244.11.26    node2   <none>           <none>
pod/jupyter-lijian                                          1/1     Running   0          13m     10.244.11.27    node2   <none>           <none>
pod/jupyter-q                                               1/1     Running   0          13m     10.244.11.28    node2   <none>           <none>
pod/jupyter-s                                               1/1     Running   0          13m     10.244.11.29    node2   <none>           <none>
pod/jupyter-z                                               1/1     Running   0          13m     10.244.38.152   node1   <none>           <none>
pod/nfs-jupyterhub-nfs-client-provisioner-6cd98c87c-b2fkk   1/1     Running   0          5h18m   10.244.11.8     node2   <none>           <none>
pod/proxy-55bcd85458-hlqnk                                  1/1     Running   0          5h17m   10.244.38.138   node1   <none>           <none>
pod/user-scheduler-865b49c54-zpxw2                          1/1     Running   0          5h17m   10.244.11.10    node2   <none>           <none>
pod/user-scheduler-865b49c54-zwj9s                          1/1     Running   0          5h17m   10.244.38.139   node1   <none>           <none>

NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
service/hub            ClusterIP   10.244.72.60     <none>        8081/TCP                     5h17m   app=jupyterhub,component=hub,release=jhub
service/proxy-api      ClusterIP   10.244.126.226   <none>        8001/TCP                     5h17m   app=jupyterhub,component=proxy,release=jhub
service/proxy-public   NodePort    10.244.125.153   <none>        443:30853/TCP,80:32688/TCP   5h17m   component=proxy,release=jhub

NAME                            HOSTS                 ADDRESS                     PORTS   AGE
ingress.extensions/jupyterhub   jupyterhub.lhws.com   10.20.80.204,10.20.80.205   80      88m
```
- NodePort形式访问
![](https://imgkr.cn-bj.ufileos.com/efe87e83-1616-48fd-b7bf-33d3e11e2704.png)
- ingress形式访问
![](https://imgkr.cn-bj.ufileos.com/c1789725-a757-40de-b9d2-9aeb620c5493.png)
左侧列表中出现的就是我自定义的部分,上面的配置文件中讲到了,有定制需求的,可以参考上面的配置文件讲解
```
FROM jupyter/base-notebook:a07573d685a4
ARG JUPYTERHUB_VERSION=1.1.*
USER root
RUN apt-get update && apt-get install --yes --no-install-recommends \
    git \
 && rm -rf /var/lib/apt/lists/*
#这里是我自定义的目录
RUN mkdir -p /dataset/ /test/ /train/ /code/
USER $NB_USER

RUN python -m pip install nbgitpuller \
    $(bash -c 'if [[ $JUPYTERHUB_VERSION == "git"* ]]; then \
       echo ${JUPYTERHUB_VERSION}; \
     else \
       echo jupyterhub==${JUPYTERHUB_VERSION}; \
     fi') && \
    jupyter serverextension enable --py nbgitpuller --sys-prefix
```
默认是/lab即jupyterlab 你也可以切换到/tree这样就是jupyternotebooks了

### 结束语
现在,ldap和jupyterhub成功关联上了,在ldap中创建的用户,可以登陆到jupyterhub中,不建议在配置文件`定制用户管理`开启admin 不利于管理,只使用ldap创建管理用户即可！


参考文献： \
https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html \
https://zero-to-jupyterhub.readthedocs.io/en/latest/customizing/user-environment.html \
https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/advanced.html
https://jupyterhub.github.io/helm-chart/ \
https://github.com/jupyterhub/zero-to-jupyterhub-k8s/blob/master/images/singleuser-sample/Dockerfile \
https://github.com/jupyterhub/zero-to-jupyterhub-k8s