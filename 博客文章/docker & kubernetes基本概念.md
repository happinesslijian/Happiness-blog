#### 概述
有朋友说docker&k8s太复杂了，涉及到的概念太多太多了，根本记不住，面试时候一次又一次的碰壁。本篇文件主要讲述docker和kubernetes的组成 基本概念等 以**一问一答** 形式来讲解。安装及实操请查看本blog其他文章！

**PS:以下都是作者的个人理解，如有不周的地方 欢迎在下方留言评论，或发邮件到`1319414778@qq.com`邮箱进行沟通！**

### docker篇

Q:
```
什么是docker？
```
A：
```
docker翻译过来是“搬运工”的意思，他搬运的东西就是我们常说的container,container里面安装的是任意APP，我们的开发人员可以通过 Docker 将App 变成一种标准化的、可移植的、自管理的组件，我们可以在任何主流的操作系统中开发、调试和运行。
```
Q:
```
docker和虚拟机有啥区别？
```
A：
```
从概念上来看docker和传统的虚拟机比较类似，只是更加轻量级，更加方便使用，区别如下：

虚拟化技术依赖的是物理CPU和内存，是硬件级别的；而我们的 Docker 是构建在操作系统层面的，利用操作系统的容器化技术，所以 Docker 同样的可以运行在虚拟机上面。

也就是说虚拟机是依赖物理硬件资源的，而docker则是依赖操作系统的，只要你是个操作系统，docker就可以安装在上面。

举个例子：
docker更加轻量级，资源占用使用率小了，成本自然就节省出来了。假如需求是部署一个redis，使用传统的虚拟化技术需要创建出一个虚拟机，然后在虚拟机上安装redis，好比是一个2c4g的虚拟机，那么redis这个服务只使用了不到1核，其余的资源岂不是浪费了？这也就是为什么使用docker的原因
```
Q:
```
叙述一下docker的架构
```
A：
```
1.一个常驻后台的进程Dockerd
2.一个用来和Dockerd 交互的 REST API Server
3.命令行CLI接口，通过和 REST API 进行交互（我们经常使用的 docker 命令）
```
Q:
```
docker的网络模式有哪几种？区别是什么？
```
A：
```
Bridge模式 Host模式 Container模式 None模式
Bridge模式是docker的默认网络模式
如果启动容器的时候使用host模式，那么这个容器将不会获得一个独立的Network Namespace，而是和宿主机共用一个 Network Namespace
这个模式指定新创建的容器和已经存在的一个容器共享一个 Network Namespace，而不是和宿主机共享
使用none模式，Docker 容器拥有自己的 Network Namespace，但是，并不为Docker 容器进行任何网络配置
```
Q:
```
docker有哪几种编排工具
```
A：
```
docker compose
docker machine
docker swarm

docker compose用来快速部署分布式应用
docker machine用来在多种平台上快速安装docker环境
docker swarm用户可以将多个 Docker 主机封装为单个大型的虚拟 Docker 主机，快速打造一套容器云平台
```

### kubernetes篇
Q:
```
什么是kubernetes 使用kubernetes的好处是什么？
```
A：
```
kubernetes是谷歌的一套容器编排工具，使用kubernetes可以跨多主机来管理容器，自动部署扩展等操作，简单来说kubernetes就是docker的容器编排系统。
kubernetes的好处是可以对每个控制器进行管理，升级回滚等操作。
```
Q:
```
kubernetes由那些组件组成？分别说一下它们的作用及使用端口
```
A：
```
master是kubernetes集群的控制节点，负责整个集群的管理控制，master节点上包含以下组件
kube-apiserver/kube-controller-manager/kubelet/kube-proxy/kube-scheduler/etcd/pod/ReplicaSet/Deployment/Service

node节点是kubernetes集群中的工作节点，node上的工作负载由master节点分配，工作负载主要是运行容器应用。Node节点上包含以下组件：
kubelet
kube-proxy
运行容器化（pod）应用

kube-apiserver：集群的控制入口，提供HTTP REST服务 API注册 服务发现 请求响应 权限控制等

kube-controller-manager：Kubernetes 集群中所有资源对象的自动化控制中心 是一个控制管理器，它会保证整个集群里所有的资源对象处于预期的运行状态。kube-controller-manager由多个controller组成 namespaces-controller replication-controller等 端口是：10252

kubelet：kubelet是kubectl工具的服务端，负责pod的创建、启动、监控、重启、删除、销毁等工作，同时和master通讯交互，实现集群管理功能 端口：10250

kube-proxy:实现 Kubernetes Service 的通信和负载均衡

kube-scheduler：负责 Pod 的调度，分为预选策略和优选策略，首先是预选策略：预选策略会看被调度的pod和node节点是否存在亲和性 即
podAffinity
podAntiAffinity
nodeAffinity
nodeSelector
等一些标签关系标签匹配等，如果存在即可被调度。如果不存在交由优选策略，优选策略是去看node节点的资源使用状态，即CPU 内存 磁盘等IO 除此之外也会看node节点已经运行pod的数量（默认是110个）资源使用率较低，运行pod数量较少的node节点会被优先调度。端口是：10251

Pod：Pod 是 Kubernetes 最基本的部署调度单元。每个 Pod 可以由一个或多个业务容器和一个根容器(Pause 容器)组成。一个 Pod 表示某个应用的一个实例

ReplicaSet：是 Pod 副本的抽象，用于解决 Pod 的扩容和伸缩

Deployment：Deployment 表示部署，在内部使用ReplicaSet 来实现。可以通过 Deployment 来生成相应的 ReplicaSet 完成 Pod 副本的创建

Service：Service 是 Kubernetes 最重要的资源对象。Kubernetes 中的 Service 对象可以对应微服务架构中的微服务。Service 定义了服务的访问入口，服务的调用者通过这个地址访问 Service 后端的 Pod 副本实例。

etcd：保存了整个集群的状态，就是一个数据库 存储的是控制器状态等 端口：2379

除了上面核心组件之外推荐安装的一些组件如下：

core-dns 负责为整个集群提供 DNS 服务
Ingress Controller 为服务提供外网入口
metrics 提供资源监控
Dashboard 提供 GUI
```
Q:
```
为什么需要kubernetes，它的能做什么？或者说它的优点是啥
```
A：
```
服务发现和负载均衡：Kubernetes 可以使用 DNS 名称或自己的 IP 地址公开容器，如果到容器的流量很大，Kubernetes 可以负载均衡并分配网络流量，从而使部署稳定。
    
存储编排：Kubernetes 允许您自动挂载您选择的存储系统，例如本地存储、公共云提供商等。
    
自动部署和回滚：您可以使用 Kubernetes 描述已部署容器的所需状态，它可以以受控的速率将实际状态更改为所需状态。例如，您可以自动化 Kubernetes 来为您的部署创建新容器，删除现有容器并将它们的所有资源用于新容器。
    
容器资源配额：Kubernetes 允许您指定每个容器所需 CPU 和内存（RAM）。当容器指定了资源请求时，Kubernetes 可以做出更好的决策来管理容器的资源。
    
自我修复：Kubernetes 重新启动失败的容器、替换容器、杀死不响应用户定义的运行状况检查的容器，并且在准备好服务之前不将其通告给客户端。
    
密钥与配置管理：Kubernetes 允许您存储和管理敏感信息，例如密码、OAuth 令牌和 ssh 密钥。您可以在不重建容器镜像的情况下部署和更新密钥和应用程序配置，也无需在堆栈配置中暴露密钥。
    
配置文件：Kubernetes 可以通过 ConfigMap 来存储配置。
```
Q:
```
什么是Namespace
```
A：
```
namespace翻译过来是命名空间的意思，在一个 Kubernetes 集群中可以使用namespace创建多个“虚拟集群”，这些namespace之间可以完全隔离，也可以通过某种方式，让一个namespace中的service可以访问到其他的namespace中的服务。
```
Q:
```
讲述pod的生命周期
```
A：
```
以下都属于pod生命周期范围
两个钩子 pod Hook
poststart 容器运行时即运行，用于资源部署，环境准备
prestop 容器终止前运行，优雅停止容器，并告知其他机器
两个探针
liveness probe 存活性探针
readiess probe 可读性探针
探测包含以下参数：
exec 用户使用一条命令
Http Get 用于检测http请求
TcpSocket 用于检测端口
两个一起使用可保证流量不会到达没有准备好的机器上
pause容器 用于管理pod网络
```
Q:
```
简单描述一下什么是deployment？为什么使用deployment
```
A:
```
Deployment用于部署无状态应用，是之前ReplicationController的升级版，方便管理应用。典型应用场景包括：
定义Deployment来创建Pod和ReplicaSet
滚动升级和回滚应用
扩容和缩容
暂停和继续Deployment
```
Q:
```
简单描述一下什么是service？service是通过什么来关联到pod的？
```
A:
```
Kubernetes Service 定义了这样一种抽象：一个 Pod 的逻辑分组，一种可以访问它们的策略 —— 通常称为 微服务。这一组 Pod 能够被 Service 访问到，通常是通过 Label Selector 实现的。
```
Q:
```
什么是ingress？讲述你所了解的ingress
```
A:
```
Ingress翻译过来是“入口”的意思即Ingress 是从 Kubernetes集群外部访问集群内部服务的入口。Ingress会把访问请求转发给不同的service来处理，（自己相当于代理服务器）从而实现“服务发现”的效果。

如果你单单只部署了Ingress是没办法完成“服务发现”的效果，因为没有一个服务端来给它做请求响应，所以还需要再部署一个Ingress-Controller来完成对ingress的请求响应。

Ingress-Controller会不断的和API-SERVER进行通信交互，来感知后端pod及service的变化，获取到变化信息之后Ingress-Controller会根据设定来完成对ingress的更新，从而完成了“服务发现”的效果。
```
Q:
```
什么是pod？
```
A:
```
pod是kubernetes中最小部署单元
Pod由一个或多个容器组成
pod中封装着应用的容器，Pod代表着集群中运行的进程。
```
Q:
```
什么是ConfigMap？ConfigMap有几种创建方式？
```
A:
```
ConfigMap 跟 Secrets 类似，但是ConfigMap更方便的处理不含敏感信息的字符串
ConfigMap用来存储非敏感信息（配置文件）
ConfigMap的两种种创建方式：
--from-file=xxx.yaml
--from-literal=key=value
```
Q:
```
什么是Secret？Secret存储哪几种类型？
```
A:
```
Secret是用来存储敏感信息，常见的有“证书” “密码”等
Secret有以下三种类型
Opaque：base64编码格式的Secret
kubernetes.io/dockerconfigjson：用来存储私有docker registry的认证信息
Service Account：用来访问Kubernetes API，由Kubernetes自动创建
```
Q:
```
描述一下PV和PVC
```
A:
```
用于数据持续存储，Pod中，容器销毁，所有数据都会被销毁，如果需要保留数据，这里就需要用到 PV存储卷，PVC存储卷申明。
PVC 常用于 Deployment 做数据持久存储。PV是实际持久化存储存放的地方，PVC是PV的申明，来帮助deployment把持久化数据存放在PV当中
PV 作为存储资源，主要包括访问模式、回收策略等关键信息
AccessModes访问模式：
ReadWriteOnce（RWO）：读写权限，但是只能被单个节点挂载
ReadOnlyMany（ROX）：只读权限，可以被多个节点挂载
ReadWriteMany（RWX）：读写权限，可以被多个节点挂载
persistentVolumeReclaimPolicy（回收策略）
Retain（保留）- 保留数据，需要管理员手工清理数据 
Recycle（回收）- 清除 PV 中的数据，效果相当于执行 rm -rf /thevoluem/* 
Delete（删除）- 与 PV 相连的后端存储完成 volume 的删除操作
```
Q:
```
什么是DaemonSet？
```
A:
```
DaemonSet是pod的控制器之一，DaemonSet就像是一个守护进程，它会部署在每一个节点上。常见的有prometheus监控集群Node的node-exporter 日志收集的fluentd或logstash 负载均衡器kube-proxy 网络插件kube-flannel等其他网络插件
DaemonSet在所有集群节点上运行一个pod，当node加入时，创建pod。node离开时，回收pod
DaemonSet并不关心一个节点的unshedulable字段。
DaemonSet可以创建Pod，即使调度器还没有启动。
```
Q:
```
什么是StatefuleSet?
```
A:
```
StatefuleSet是pod控制器之一，是专门部署有状态应用的。
StatefuleSet具有以下功能：
稳定、唯一的网络标识
稳定、持久化的存储
有序的、优雅的部署和缩放
有序的、优雅的删除和终止
有序的、自动滚动更新
```
Q:
```

```
A:
```

```
Q:
```

```
A:
```

```
Q:
```

```
A:
```

```
