# 部署permission-manager
[参考链接](https://github.com/sighupio/permission-manager)
### 部署permission-manager所需依赖
```
# 把该项目克隆到本地
git clone https://github.com/sighupio/permission-manager.git

# 部署permission-manager所需依赖
kubectl apply -f k8s/k8s-seeds/namespace.yml
kubectl apply -f k8s/k8s-seeds
```
### 修改部署文件:

|Env Name|Description|中文翻译|
|:--:|:--:|:--:|
|PORT|port where server is exposed|服务器暴露端口|
|CLUSTER_NAME|name of the cluster to use in the generated kubeconfig file|在生成的kubeconfig文件中使用的集群名称|
|CONTROL_PLANE_ADDRESS|full address of the control plane to use in the generated kubeconfig file|APIServer的地址|
|BASIC_AUTH_PASSWORD|password used by basic auth (username is admin)|基本身份验证使用的密码（用户名为admin）|

```
apiVersion: apps/v1                                         
kind: Deployment
metadata:
  namespace: permission-manager
  name: permission-manager-deployment
  labels:
    app: permission-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: permission-manager
  template:
    metadata:
      labels:
        app: permission-manager
    spec:
      serviceAccountName: permission-manager-service-account
      containers:
        - name: permission-manager
          image: quay.io/sighup/permission-manager:1.5.0
          ports:
            - containerPort: 4000
          env:
            - name: PORT
              value: "4000"
            - name: CLUSTER_NAME
              value: "kubernetes"
            - name: CONTROL_PLANE_ADDRESS
              value: "https://192.168.100.154:6443"
            - name: BASIC_AUTH_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: auth-password-secret
                  key: password
---
apiVersion: v1
kind: Service
metadata:
  namespace: permission-manager
  name: permission-manager-service
spec:
  selector:
    app: permission-manager
  type: NodePort
  ports:
    - protocol: TCP
      port: 4000
      targetPort: 4000
```
> 我这里改了 **CLUSTER_NAME** 
 **CONTROL_PLANE_ADDRESS** 
 **Service** 换成了 **NodePort** 模式

### 部署permission-manager
```
# 部署permission-manager
kubectl apply -f k8s/deploy.yaml
```
### 通过NodePort模式访问
```
kubectl get svc -n permission-manager
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
permission-manager-service   NodePort   10.244.118.59   <none>        4000:32172/TCP   43m

# 浏览器输入 192.168.100.154:32172 进入dashboard
```
### 使用方法
![](https://imgkr.cn-bj.ufileos.com/c0d7cabe-99e9-4f7f-9df0-7b8e487ea684.gif)

创建一个名为test的用户
![](https://imgkr.cn-bj.ufileos.com/53107cd5-8db7-4613-a395-1643166f73b1.png)
保存之后点击 **show kubeconfig for test**
在弹出的框内复制如下内容到.kube/config文件内
```
contexts:
  - context:
      cluster: kubernetes
      user: test
    name: kubernetes
users:
  - name: test
    user:
      client-certificate-data: xxxx==
      client-key-data: xxxx==
```
`vim .kube/config `
如下图所示:
![](https://imgkr.cn-bj.ufileos.com/2de1c402-5064-49b8-a0f2-8f8bfbf7c233.png)
接下来切换上下文到test
```
kubectl config use-context test

kubectl get pod 
Error from server (Forbidden): pods is forbidden: User "test" cannot list resource "pods" in API group "" in the namespace "default"
# 上面的报错是说对默认命名空间没有权限因为刚才我们创建test上下文的时候针对的是test命名空间
kubectl run nginx --image=nginx -n test
针对test命名空间创建一个nginx
kubectl get pod -n test
NAME                     READY   STATUS    RESTARTS   AGE
nginx-7bb7cd8db5-r7b8m   1/1     Running   0          46s
```
### 常用命令
```
查看现有的上下文
kubectl config get-contexts
切回所有权的上下文
kubectl config use-context kubernetes-admin@kubernetes
查看现在是哪个上下文
kubectl config current-context
查看现有集群名称
kubectl config get-clusters
删除某个上下文
kubectl config delete-context test
```
> **注意：** 在auth-secret.yml文件中,默认使用的是明文 **stringData** 如下：
当然你可以换成密文 **Data**使用base64进行加密
```
apiVersion: v1
kind: Secret
metadata:
  name: auth-password-secret
  namespace: permission-manager
type: Opaque
stringData:
  password: 1v2d1e2e67dS
```
### 总结：鼠标点点点创建用户或针对某个命名空间
[命令行创建参考](https://blog.k8s.fit/articles/2019/12/11/1576045930241.html)