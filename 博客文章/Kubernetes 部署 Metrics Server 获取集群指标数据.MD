# Kubernetes 部署 Metrics Server 获取集群指标数据
![](https://static01.imgkr.com/temp/b682af138363458ba60a3953b10f54a7.jpg)

**系统环境：**

- Kubernetes 版本：1.17.4
- Metrics Server 版本：0.3.6
**例部署文件地址：**

- Kubernetes 部署 Metrics Server 部署文件
## 一、Metrics Server 简介
       介绍 Metrics Server 前首先介绍下 Heapster，该工具是用于 Kubernetes 集群监控和性能分析工具，可以收集节点上的指标数据，例如，节点的 CPU、Memory、Network 和 Disk 的 Metric 数据。不过在 Kubernetes V1.11 版本后将被逐渐废弃。而 Metrics Server 正是 Heapster 的代替者。

       Metrics Server 是 Kubernetes 集群核心监控数据的聚合器，可以通过 Metrics API 的形式获取 Metrics 数据，不过仅仅是获取指标的最新值，不对旧值进行存储，且不负责将指标转发到第三方目标。Metrics Server 还可以与 Kubectl 工具结合使用，提供 kubectl top 命令来展示集群中的指标数据，接下来我们开始部署 Metrics Server。
## 二、部署应用权限 RBAC 资源
Kubernetes 部署 Metrics Server 前需要先提前部署 RBAC 相关配置，这样 Metrics Server 才能有足够的权限获取系统组件的信息。

**创建 Metrics RBAC 文件**
metrics-rbac.yaml
```
## ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
## ClusterRole aggregated-metrics-reader
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:aggregated-metrics-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods","nodes"]
  verbs: ["get","list","watch"]
---
## ClusterRole metrics-server
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:metrics-server
rules:
- apiGroups: [""]
  resources: ["pods","nodes","nodes/stats","namespaces","configmaps"]
  verbs: ["get","list","watch"]
---
## ClusterRoleBinding auth-delegator
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
## RoleBinding metrics-server-auth-reader
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
## ClusterRoleBinding system:metrics-server
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
```
**通过 Kubectl 工具部署 Metrics RBAC**
- -n：指定部署应用的 Namespace 命名空间
```
$ kubectl apply -f metrics-rbac.yaml -n kube-system
```
## 三、部署 APIService 资源
设置扩展 API Service 工作于聚合层，允许使用其 API 扩展 Kubernetes apiserver，而这些 API 并不是核心 Kubernetes API 的一部分。这里部署 APIservice 资源，来提供 Kubernetes Metrics 指标 API 数据。

**创建 Metrics APIService 文件**
metrics-api-service.yaml
```
## APIService
apiVersion: apiregistration.k8s.io/v1beta1
kind: APIService
metadata:
  name: v1beta1.metrics.k8s.io
spec:
  service:
    name: metrics-server
    namespace: kube-system
  group: metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
```
**通过 Kubectl 工具部署 Metrics APIService**
- -n：指定部署应用的 Namespace 命名空间
```
$ kubectl apply -f metrics-api-service.yaml -n kube-system
```
## 四、部署 Metrics Server 应用
**创建 Metrics 部署文件**
metrics-server-deploy.yaml
```
## Service
apiVersion: v1
kind: Service
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    kubernetes.io/name: "Metrics-server"
    kubernetes.io/cluster-service: "true"
spec:
  selector:
    k8s-app: metrics-server
  ports:
  - port: 443
    targetPort: 4443
---
## Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      hostNetwork: true
      serviceAccountName: metrics-server
      containers:
      - name: metrics-server
        image: registry.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.6
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-insecure-tls
          - --kubelet-preferred-address-types=InternalDNS,InternalIP,ExternalDNS,ExternalIP,Hostname
        ports:
        - name: main-port
          containerPort: 4443
          protocol: TCP
        securityContext:
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        resources:
          limits:
            memory: 1Gi
            cpu: 1000m
          requests:
            memory: 1Gi
            cpu: 1000m
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
        - name: localtime
          readOnly: true
          mountPath: /etc/localtime
      volumes:
      - name: tmp-dir
        emptyDir: {}
      - name: localtime
        hostPath:
          type: File
          path: /etc/localtime
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: "amd64"
```
**通过 Kubectl 工具部署 Metrics 应用**
- -n：指定部署应用的 Namespace 命名空间
```
$ kubectl apply -f metrics-server-deploy.yaml -n kube-system
```
## 五、进行测试
当部署完 Metrics Server 后，可以通过 kubectl 工具进行测试，默认支持下面命令：

- kubectl top pod： 获取 Pod 的 CPU、Memory 使用信息。
- kubectl top node： 获取 Node 的 CPU、Memory 使用信息。
输入上面命令进行测试，如下：
```
## 获取全部节点指标信息
$ kubectl top node
NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
k8s-master      228m         5%     1204Mi          44%       
k8s-node-2-12   131m         1%     1843Mi          23%       
k8s-node-2-13   73m          0%     576Mi           7%     

## 获取某个 Namespace Pod 的指标信息
$ kubectl top pods -n kube-system
NAME                                         CPU(cores)   MEMORY(bytes)   
coredns-9d85f5447-c82w7                      7m           22Mi            
coredns-9d85f5447-kcmb4                      7m           21Mi            
dashboard-metrics-scraper-65f454dff8-2pts8   1m           22Mi            
etcd-k8s-master                              22m          104Mi           
kube-apiserver-k8s-master                    58m          311Mi           
kube-controller-manager-k8s-master           27m          46Mi

## 获取某个 Namespace 下某个 Pod 的指标信息
$ kubectl top pods coredns-9d85f5447-c82w7 -n kube-system
NAME                      CPU(cores)   MEMORY(bytes)
coredns-9d85f5447-c82w7   7m           21Mi  

## 获取全部 Namespace 下的 Pod 的指标信息
$ kubectl top pods --all-namespaces
NAMESPACE     NAME                                           CPU(cores)   MEMORY(bytes)
kube-system   coredns-9d85f5447-c82w7                        6m           22Mi            
kube-system   coredns-9d85f5447-kcmb4                        6m           21Mi            
kube-system   dashboard-metrics-scraper-65f454dff8-2pts8     1m           22Mi            
kube-system   etcd-k8s-master                                21m          106Mi           
kube-system   kube-apiserver-k8s-master                      62m          311Mi           
kube-system   kube-controller-manager-k8s-master             26m          46Mi            
kube-system   kube-proxy-kpt7c                               2m           36Mi            
kube-system   kube-proxy-zb2l5                               1m           27Mi            
kube-system   kube-scheduler-k8s-master                      5m           21Mi            
kube-system   kubernetes-dashboard-7bf47cd79c-nctx2          1m           55Mi            
kube-system   metrics-server-6d54447849-nnbfk                3m  
```