# 垂直 Pod 自动缩放器

### 前言
为您的工作负载设置正确的资源请求和限制对于稳定性和成本效率非常重要。如果您的 Pod 资源大小小于您的工作负载所需，您的应用程序可能会受到限制，或者由于内存不足错误而失败。如果您的资源规模太大，您就会产生浪费，因此会产生更大的费用。
简而言之，如果您没有正确设置请求/限制，您的应用程序可能会失败/被限制，或者您将过度配置您的资源，这将花费您很多。

### 简述VPA
Vertical Pod Autoscaler (VPA) 使用户无需为 Pod 中的容器设置最新的资源限制和请求。配置VPA后，它将根据使用情况自动设置请求，从而允许在节点上进行适当的调度，以便为每个 pod 提供适当的资源量。它还将维护初始容器配置中指定的限制和请求之间的比率。
它既可以缩小过度请求资源的 Pod，也可以根据随着时间的推移对资源请求不足的 Pod 进行放大。

VPA 部署包含三个组件：
Recommender，它监视资源利用率并计算目标值。
Updater 驱逐需要用新资源限制更新的 Pod。
Admission Controller 则使用 mutating admission webhook 重写了一个具有正确资源调度的 Pod。


### 环境简介
| name | status | roles | age | version |
| :---: | :---: | :---: | :---: | :---: |
| master | ready | control-plane,etcd,master | 56d | v1.19.4 |
| node1 | ready | worker | 56d | v1.19.4 |
| node2 | ready | worker | 56d | v1.19.4 |


### 安装 Vertical Pod Autoscaler
[参考链接](https://github.com/kubernetes/autoscaler/tree/master)

```
git clone https://ghproxy.com/https://github.com/kubernetes/autoscaler.git
./vertical-pod-autoscaler/hack/vpa-up.sh
```
> 我在安装后立即发现的问题之一是' ContainerCreating ' 状态下的 ' vpa-admission-controller ' ：
```
kube-system            vpa-admission-controller-6cd546c4f-nw457     0/1     ContainerCreating   0          2m19s
kube-system            vpa-recommender-6855ff754-vbbcq              0/1     ErrImagePull        0          2m18s
kube-system            vpa-updater-998bd8df9-qjtkm                  0/1     ImagePullBackOff    0          2m20s
```
> 要解决此问题，请将 openssl 升级到 1.1.1 或更高版本（需要支持 -addext 选项）或在0.8 发布分支上使用 ./hack/vpa-up.sh 我这里使用0.8版本进行部署
```
git clone -b vpa-release-0.8 https://ghproxy.com/https://github.com/kubernetes/autoscaler.git
cd autoscaler/
./vertical-pod-autoscaler/hack/vpa-up.sh
```
> 因国内拉取镜像比较困难,我把用到的images同步到我的阿里云镜像仓库中,编辑deploy修改images即可
```
kubectl patch deploy -n kube-system vpa-admission-controller --patch '{"spec": {"template": {"spec": {"containers": [{"name": "admission-controller","image": "registry.cn-zhangjiakou.aliyuncs.com/lijianhappiness/vpa:vpa-admission-controller-version-0.8.1"}]}}}}'
kubectl patch deploy -n kube-system vpa-recommender --patch '{"spec": {"template": {"spec": {"containers": [{"name": "recommender","image": "registry.cn-zhangjiakou.aliyuncs.com/lijianhappiness/vpa:vpa-recommender-version-0.8.1"}]}}}}'
kubectl patch deploy -n kube-system vpa-updater --patch '{"spec": {"template": {"spec": {"containers": [{"name": "updater","image": "registry.cn-zhangjiakou.aliyuncs.com/lijianhappiness/vpa:vpa-updater-version-0.8.1"}]}}}}'
## 查看pod
kubectl get pod -n kube-system | grep vpa
[root@master autoscaler]# kubectl get pod -n kube-system | grep vpa
vpa-admission-controller-6f999f8ffc-xl7kq   1/1     Running   0          78s
vpa-recommender-5dddc988fd-bjf2f            1/1     Running   0          28s
vpa-updater-c969ccd98-px2ww                 1/1     Running   0          18s
```
### 验证
- 部署一个nginx
```
## nginx-deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```
### 为 deployment 管理器部署 VPA 清单
```
## vim cm-vpa.yaml

apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: cm-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: nginx-deployment
  updatePolicy:
    updateMode: "Off"
```
> UpdateMode：'Off'，意味着我们仅在推荐模式下使用VPA。

### 从已部署的 VPA 清单中获取建议

```
kubectl describe vpa cm-vpa

 Recommendation:
   Container Recommendations:
     Container Name:  nginx
     ···
     Target:
       Cpu:     25m
       Memory:  262144k
## 查看Recommendation/Target部分，这是容器的推荐 CPU 请求和内存请求。
```
### 很简单，您唯一需要做的就是部署 cm-vpa.yaml 清单 [或者使用](https://goldilocks.docs.fairwinds.com/installation/#requirements)

```
## 我使用清单部署
git clone https://ghproxy.com/https://github.com/FairwindsOps/goldilocks.git
cd goldilocks
kubectl create namespace goldilocks
kubectl -n goldilocks apply -f hack/manifests/controller
kubectl -n goldilocks apply -f hack/manifests/dashboard
kubectl -n goldilocks port-forward svc/goldilocks-dashboard 8080:80
```
### 启用命名空间
- 选择一个应用程序命名空间并像这样标记它，以便查看一些数据：
```
kubectl label ns goldilocks goldilocks.fairwinds.com/enabled=true

```

[参考链接](https://faun.pub/practical-example-of-how-to-set-requests-and-limits-on-kubernetes-87521b599983)

