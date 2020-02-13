### 以下 Daemonset yaml 中，哪些是正确的？
```
A. apiVersion: apps/v1 kind:  DaemonSet metadata: name: fluentd-elasticsearch namespace:  default labels: k8s-app: fluentd-logging spec: selector: matchLabels: name: fluentd-elasticsearch template: metadata: labels: name: fluentd-elasticsearch spec: containers:  - name: fluentd-elasticsearch image: gcr.io/fluentd-elasticsearch/fluentd:v2.5.1 restartPolicy:  Never
B. apiVersion: apps/v1 kind:  DaemonSet metadata: name: fluentd-elasticsearch namespace:  default labels: k8s-app: fluentd-logging spec: selector: matchLabels: name: fluentd-elasticsearch template: metadata: labels: name: fluentd-elasticsearch spec: containers:  - name: fluentd-elasticsearch image: gcr.io/fluentd-elasticsearch/fluentd:v2.5.1 restartPolicy:  Onfailure
C. apiVersion: apps/v1 kind:  DaemonSet metadata: name: fluentd-elasticsearch namespace:  default labels: k8s-app: fluentd-logging spec: selector: matchLabels: name: fluentd-elasticsearch template: metadata: labels: name: fluentd-elasticsearch spec: containers:  - name: fluentd-elasticsearch image: gcr.io/fluentd-elasticsearch/fluentd:v2.5.1 restartPolicy:  Always
D. apiVersion: apps/v1 kind:  DaemonSet metadata: name: fluentd-elasticsearch namespace:  default labels: k8s-app: fluentd-logging spec: selector: matchLabels: name: fluentd-elasticsearch template: metadata: labels: name: fluentd-elasticsearch spec: containers:  - name: fluentd-elasticsearch image: gcr.io/fluentd-elasticsearch/fluentd:v2.5.1
```
**答案：C D**
*https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/*
> A Pod Template in a DaemonSet must have a RestartPolicy equal to Always, or be unspecified, which defaults to Always. Daemonset里的pod Template下必须有RestartPolicy，如果没指定，会默认为Always.

另外Deployment、Statefulset的restartPolicy也必须为Always，保证pod异常退出，或者健康检查 livenessProbe失败后由kubelet重启容器。*https://kubernetes.io/zh/docs/concepts/workloads/controllers/deployment*

Job和CronJob是运行一次的pod，restartPolicy只能为OnFailure或Never，确保容器执行完成后不再重启。*https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/*

### 在Kubernetes PVC+PV体系下通过CSI实现的volume plugins动态创建pv到pv可被pod使用有哪些组件需要参与？
```
A.  PersistentVolumeController  + CSI-Provisoner  + CSI controller plugin
B.  AttachDetachController  + CSI-Attacher  + CSI controller plugin
C.  Kubelet  + CSI node plugin
```
**答案：ABC**

用户提交请求创建pod，PersistentVolumeController发现这个pod声明使用了PVC，那就会帮它找一个PV配对。

没有现成的PV，就去找对应的StorageClass，帮它新创建一个PV，然后和PVC完成绑定。

新创建的PV，还只是一个API 对象，需要经过“**两阶段处理**”，才能变成宿主机上的“持久化 Volume”真正被使用：

**第一阶段**由运行在master上的AttachDetachController负责，为这个PV完成 Attach 操作，为宿主机挂载远程磁盘；

**第二阶段**是运行在每个节点上kubelet组件的内部，把第一步attach的远程磁盘 mount 到宿主机目录。这个控制循环叫VolumeManagerReconciler，运行在独立的Goroutine，不会阻塞kubelet主控制循环。

完成这两步，PV对应的“持久化 Volume”就准备好了，POD可以正常启动，将“持久化 Volume”挂载在容器内指定的路径。

### 通过单个命令创建一个deployment并暴露Service。deployment和Service名称为cka-1120，使用nginx镜像， deployment拥有2个pod
**答案：**
```
kubectl run cka-1120 --image nginx --replicas 2 --expose --port 80
kubectl get pod,svc | grep cka-1120
```
### 通过命令行，使用nginx镜像创建一个pod并手动调度到节点名为node1121节点上，Pod的名称为cka-1121，注意：手动调度是指不需要经过kube-scheduler去调度。
**答案：**
```
apiVersion: v1
kind: Pod
metadata:
  name: cka-1121
  labels:
    app: cka-1121
spec:
  containers:
  - name: cka-1121
    image: busybox
    command: ['sh', '-c', 'echo Hello CKA! && sleep 3600']
  nodeName: node1121
```
指定了 **nodeName**就不会经过kube-scheduler去调度
kubeadm安装的集群，master节点上的kube-apiserver、kube-scheduler、kube-controller-manager、etcd就是通过static Pod方式部署的目录是`/etc/kubernetes/manifests`

### 通过命令行，创建两个deployment
* 需要集群中有2个节点 ；    
* 第1个deployment名称为cka-1122-01，使用nginx镜像，有2个pod，并配置该deployment自身的pod之间在节点级别反亲和；
* 第2个deployment名称为cka-1122-02，使用nginx镜像，有2个pod，并配置该deployment的pod与第1个deployment的pod在节点级别亲和；
**答案：**
```
#第1个deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cka-1122-01
  name: cka-1122-01
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cka-1122-01
  template:
    metadata:
      labels:
        app: cka-1122-01
    spec:
      containers:
      - image: nginx
        name: cka-1122-01  
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - cka-1122-01
              topologyKey: "kubernetes.io/hostname"
```
第2个deployment
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cka-1122-02
  name: cka-1122-02
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cka-1122-02
  template:
    metadata:
      labels:
        app: cka-1122-02
    spec:
      containers:
      - image: nginx
        name: cka-1122-02
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - cka-1122-01
            topologyKey: "kubernetes.io/hostname"
```
亲和性包括：
```
podAffinity
podAntiAffinity
nodeAffinity
nodeSelector
```
策略包括：
```
requiredDuringSchedulingIgnoredDuringExecution
preferredDuringSchedulingIgnoredDuringExecution
```
### 创建1个deployment，副本数为3，镜像为nginx:latest。然后滚动升级到nginx:1.9.1，再回滚到原来的版本.Deployment的名称为cka-1125
先创建deployment 可以用命令创建也可以使用yaml创建
```
kubectl run cka-1125 --image=nginx --replicas=3
```
```
apiVersion: 
apps/v1  
kind: Deployment  
metadata:  
  labels:  
    app: cka-1125  
  name: cka-1125  
spec:  
  replicas: 3  
  selector:  
    matchLabels:  
      app: cka-1125  
  template:  
    metadata:  
      labels:  
        app: cka-1125  
    spec:  
      containers:  
      - image: nginx  
        name: cka-1125
```
创建
```
kubectl apply -f cka-1125.yaml
```
升级：
```
kubectl set image deploy cka-1125 cka-1125=nginx:1.9.1 --record
```
回滚：
```
# 回滚到上一个版本  
kubectl rollout undo deploy/cka-1125  
# 回滚到指定版本  
kubectl rollout undo deploy/cka-1125 --to-revision=1
```
内容解析：
![40499e5af7bd0850.png](https://imgkr.cn-bj.ufileos.com/744bc864-b71a-4b97-bafe-90d4921a6615.png)
--record指定，在annotation中记录当前的kubectl命令。如果设置为false，则不记录命令。如果设置为true，则记录命令。默认为false。
### roll命令
```
#查看升级状态
kubectl rollout status deploy deployname
#暂停升级
kubectl rollout pause deploy deployname
#继续升级
kubectl rollout resume deploy deployname
#升级历史记录
kubectl rollout history deploy deployname
```
roll可以管理`deployments、daemonsets、statefulsets`资源的回滚
### 滚动更新策略
```
minReadySeconds: 5  
strategy:  
  type: RollingUpdate  
  rollingUpdate:  
    maxSurge: 1  
    maxUnavailable: 1
```
**minReadySeconds**
Kubernetes在等待设置的时间后才进行升级
**maxSurge**
控制滚动更新过程中副本总数超过DESIRED的上限。maxSurge可以是具体的整数，也可以是百分比，向上取整。maxSurge默认值为25%
**maxUnavaible**  
控制滚动更新过程中，不可用副本占DESIRED的最大比例。maxUnavailable可以是具体的整数，也可以是百分之百，向下取整。默认值为25%
**maxSurge越大，初始创建的新副本数量就越多；maxUnavailable越大，初始销毁的旧副本数目就越多。**
### 提供一个pod的yaml，要求添加Init Container，Init Container的作用是创建一个空文件，pod的Containers判断文件是否存在，不存在则退出
```
apiVersion: v1  
kind: Pod  
metadata:  
  labels:  
    run: cka-1126  
  name: cka-1126  
spec:  
  initContainers:  
  - image: busybox  
    name: init-c  
    command: ['sh', '-c', 'touch /tmp/cka-1126']  
    volumeMounts:  
    - name: workdir  
      mountPath: "/tmp"  
  containers:  
  - image: busybox  
    name: cka-1126  
    command: ['sh', '-c', 'ls /tmp/cka-1126 && sleep 3600 || exit 1']  
    volumeMounts:  
    - name: workdir  
      mountPath: "/tmp"  
  volumes:  
  - name: workdir  
    emptyDir: {}
```
init容器和主容器挂载同一个workdir目录,init容器在里面创建一个空文件,主容器去检查文件是否存在。
init容器提供了容器初始化工作,也就是为主容器准备需要的依赖等条件。
init容器提供了阻塞容器的启动方式,必须在initcontainer启动完成之后再去启动主容器。
### 创建Secret名为cka1127-secret，内含有password字段，值为cka1127，然后在名为cka1127-01的Pod1里使用ENV进行调用，名为cka1127-02的Pod2里使用Volume挂载在/data 下
**创建secret方式一**
```
apiVersion: v1  
kind: Secret  
metadata:  
  name: cka1127-secret  
type: Opaque  
stringData:  
  cka1127-password: cka1127
```
**创建secret方式二**
```
kubectl create secret generic cka1127-secret --from-literal=password=cka1127
```
**名为cka1127-02的Pod yaml**
```
apiVersion: v1  
kind: Pod  
metadata:  
  name: cka1127-01  
spec:  
  containers:  
  - name: nginx  
    image: nginx  
    volumeMounts:  
    - name: pwd  
      mountPath: /data/password  
      readOnly: true  
  volumes:  
  - name: pwd  
    secret:  
      secretName: cka1127-secret
```
volume形式验证，保证/data/password/下有password文件，文件内容为明文cka1127
```
kubectl exec -ti cka1127-01 sh
ls -l /data/password
```
环境变量形式验证，保证env能查到name为PASSWORD的环境变量；
```
kubectl exec -ti cka1127-02  bash
echo $PASSWORD
```
# 创建一个Role(只有cka namespace下pods的所有操作权限)和RoleBinding(使用serviceaccount认证鉴权),使用对应serviceaccount作为认证信息对cka namespace下的pod进行操作以及对default namespace下的pods进行操作 Role和RoleBinding的名称的名称为cka-1202-role、cka-1202-rb
 创建serviceaccount：
```
[root@k8s-master ~]# kubectl create serviceaccount cka-1202-sa -n cka -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2019-10-08T22:43:48Z"
  name: cka-1202-sa
  namespace: cka
  resourceVersion: "5919532"
  selfLink: /api/v1/namespaces/cka/serviceaccounts/cka-1202-sa
  uid: 3da6448b-7d17-4cae-a1ca-5b3b1903b877
```
创建role
```
[root@k8s-master ~]# kubectl create role cka-1202-role -n cka --verb=* --resource=pods -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: "2019-10-08T23:35:59Z"
  name: cka-1202-role
  namespace: cka
  resourceVersion: "5926085"
  selfLink: /apis/rbac.authorization.k8s.io/v1/namespaces/cka/roles/cka-1202-role
  uid: d1a9f483-0deb-4486-813d-7da1d2f017cd
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - '*'
```
创建rolebinding
```
[root@k8s-master ~]# kubectl create rolebinding cka-1202-rb --role=cka-1202-role --serviceaccount=cka:cka-1202-sa -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2019-10-08T23:55:05Z"
  name: cka-1202-rb
  namespace: default
  resourceVersion: "5928484"
  selfLink: /apis/rbac.authorization.k8s.io/v1/namespaces/default/rolebindings/cka-1202-rb
  uid: b567c5a9-73ef-4f3b-8a8b-6df38011cf87
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cka-1202-role
subjects:
- kind: ServiceAccount
  name: cka-1202-sa
  namespace: cka
```
验证：
- 获取到`cka-1202-sa`这个`Service Account`绑定的`secret`并`base64 -d`解码`token`字段
```
[root@k8s-master ~]# kubectl get sa -n cka
kubectNAME          SECRETS   AGE
cka-1202-sa   1         75m
default       1         75m
[root@k8s-master ~]# kubectl get secret -n cka
NAME                      TYPE                                  DATA   AGE
cka-1202-sa-token-cf29m   kubernetes.io/service-account-token   3      75m
default-token-pkkgv       kubernetes.io/service-account-token   3      75m
[root@k8s-master ~]# kubectl get secret cka-1202-sa-token-cf29m -n cka -o yaml
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMwakNDQWJxZ0F3SUJBZ0lKQUpLUjI2bmY3aWRwTUEwR0NTcUdTSWIzRFFFQkN3VUFNQlV4RXpBUkJnTlYKQkFNTUNtdDFZbVZ5Ym1WMFpYTXdJQmNOTVRrd09ESTVNRFEwTmpVMVdoZ1BNakV4T1RBNE1EVXdORFEyTlRWYQpNQlV4RXpBUkJnTlZCQU1NQ210MVltVnlibVYwWlhNd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFDMWZncTR3QlZLa01kVGppakZUUXpVUzN1ejJPaFdxSUxhL3NmZHI5a3NJR2NmY0sxN0hIaTIKa3FsVUcrajNNWjV6cks3SE1vY0doTzJaK2dOR2dSVEd3OUFsVTlhVDlyS0s2OU5nYkJaWWREc0Eydk5wZHMzWApMaDlFbnV4NmY0aHdVak5JSDlzbWFreFJSTndKSEQwQS8wR3lpeVhPdyt5ZHl0OVk1YXNabzlOcHZiWWwycTBpCmVSSFlZRmpSY3hUU29YMVVzME43ZSs5NlBVeW82dFNmSnZGSjZNdDlaWTF5MjhtS3ZtV3BYbDlIamh0M01IVTAKUldGQWxzNWNWTHNGYjZQYU0rT3lINS9XU3o3VWIvSjhmbTcwMTI3bTJVNlR6cnE4bWJ3QTJSUHJ4T0E1N2RWbwpYUmVLSGhTNVhZRkVDTTFPY3BSVEtXLzZXUVd3Z1IvM0FnTUJBQUdqSXpBaE1BOEdBMVVkRXdFQi93UUZNQU1CCkFmOHdEZ1lEVlIwUEFRSC9CQVFEQWdLa01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQTY4d2xWN1lKVEpWVUoKc05OY0hsRHRjUnh0OFFwbHFKNEpsaXRoVjlicEZKeTd4YlIrMDdDTWQ2a2FJUnd4QVRWeFdEMFdPVlNSb010ZAozampkeGdvbkZxVm9IR3VEWDVTcEFSRk5vR0lSSnI0Y2dlL3dwNVZnMk1ZeGpLZWhUL0xndGlBV3BWOGhOZmhMCkxBY044bHorZ2xnQldjN1BCTmQxaDcwcU1XeXZuMWpCbnAvemtEL0NIeWJDSEFoY1dqRlhQMnhzdDhCZUNOdXEKc2xrUlZRNEdaVzRpVGlYaUJSN1ZhVUJ5ZWZoTnZFY1hEc1VzNVJhOUxaL1pXd01aQ0Q0NVV6dEZvTUwxRUw5VQptUnBJcUJhSUVSYnN3NUw2K3lSVjJ4Zm9QekFwZGIxVnN3VUlaYTlJU1JsMTdJc2xFd1kyTW9YOXBUU1lYNWk2CkxPbkR3cTg4Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
  namespace: Y2th
  token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmphMkVpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxZM0psZEM1dVlXMWxJam9pWTJ0aExURXlNREl0YzJFdGRHOXJaVzR0WTJZeU9XMGlMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lZMnRoTFRFeU1ESXRjMkVpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxjblpwWTJVdFlXTmpiM1Z1ZEM1MWFXUWlPaUl6WkdFMk5EUTRZaTAzWkRFM0xUUmpZV1V0WVRGallTMDFZak5pTVRrd00ySTROemNpTENKemRXSWlPaUp6ZVhOMFpXMDZjMlZ5ZG1salpXRmpZMjkxYm5RNlkydGhPbU5yWVMweE1qQXlMWE5oSW4wLm1Mc3MwbVo5VTNzakZDM2JaWkV6QmZoQmRYWExYWHh6WHp0RGQwZ2c2bHB6LTBzMlpvWWZfZzctcGV1alZXaGc4X0sxMEFjOVhCdS13YzBKUW5VWHBFTWZTd3JVNFBOWnNHekd3MFp3SWJEWlVqN0dOZnh6aTRoWlZFalZQUE42b19qZmQ2cUpVbFNXdndWTEoyWkRucnU5a09fcnNvTmp5Q1EyY3FVWS1oSUxMMFBmUDhwYTFrbTBhUWkwWWFHaDJOZHJtblhYMkd5V19tQTZWMDkyckFnUk1KeEE2eGgyQW1fN3YzUU5sQlN2ajc2UXNMM2x6Um5yVm1YZkIxSnFzVHNmQ3ZkR3BaSWxDZUdNeDJrbUk3MjZwemlxTmpKcHlITFl1ZG11Nm5ZTmNHdFBYajZUZ09qUTc4VlBJdXk3MnlndmxtdGdMcElMMjBkdExUbW1iQQ==
kind: Secret
metadata:
  annotations:
    kubernetes.io/service-account.name: cka-1202-sa
    kubernetes.io/service-account.uid: 3da6448b-7d17-4cae-a1ca-5b3b1903b877
  creationTimestamp: "2019-10-08T22:43:48Z"
  name: cka-1202-sa-token-cf29m
  namespace: cka
  resourceVersion: "5919533"
  selfLink: /api/v1/namespaces/cka/secrets/cka-1202-sa-token-cf29m
  uid: f9e014df-b67f-4695-876c-c9b642e4d3a8
type: kubernetes.io/service-account-token
```
解码：
```
echo "ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklpSjkuZXlKcGMzTWlPaUpyZFdKbGNtNWxkR1Z6TDNObGNuWnBZMlZoWTJOdmRXNTBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5dVlXMWxjM0JoWTJVaU9pSmphMkVpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxZM0psZEM1dVlXMWxJam9pWTJ0aExURXlNREl0YzJFdGRHOXJaVzR0WTJZeU9XMGlMQ0pyZFdKbGNtNWxkR1Z6TG1sdkwzTmxjblpwWTJWaFkyTnZkVzUwTDNObGNuWnBZMlV0WVdOamIzVnVkQzV1WVcxbElqb2lZMnRoTFRFeU1ESXRjMkVpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxjblpwWTJVdFlXTmpiM1Z1ZEM1MWFXUWlPaUl6WkdFMk5EUTRZaTAzWkRFM0xUUmpZV1V0WVRGallTMDFZak5pTVRrd00ySTROemNpTENKemRXSWlPaUp6ZVhOMFpXMDZjMlZ5ZG1salpXRmpZMjkxYm5RNlkydGhPbU5yWVMweE1qQXlMWE5oSW4wLm1Mc3MwbVo5VTNzakZDM2JaWkV6QmZoQmRYWExYWHh6WHp0RGQwZ2c2bHB6LTBzMlpvWWZfZzctcGV1alZXaGc4X0sxMEFjOVhCdS13YzBKUW5VWHBFTWZTd3JVNFBOWnNHekd3MFp3SWJEWlVqN0dOZnh6aTRoWlZFalZQUE42b19qZmQ2cUpVbFNXdndWTEoyWkRucnU5a09fcnNvTmp5Q1EyY3FVWS1oSUxMMFBmUDhwYTFrbTBhUWkwWWFHaDJOZHJtblhYMkd5V19tQTZWMDkyckFnUk1KeEE2eGgyQW1fN3YzUU5sQlN2ajc2UXNMM2x6Um5yVm1YZkIxSnFzVHNmQ3ZkR3BaSWxDZUdNeDJrbUk3MjZwemlxTmpKcHlITFl1ZG11Nm5ZTmNHdFBYajZUZ09qUTc4VlBJdXk3MnlndmxtdGdMcElMMjBkdExUbW1iQQ==" | base64 -d
```
把解码后的信息添加到将添加到`~/.kube/config`中，注意到下面加了`name为coderaction的context和name为coderaction的user`
```
vim .kube/config

apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMwakNDQWJxZ0F3SUJBZ0lKQUpLUjI2bmY3aWRwTUEwR0NTcUdTSWIzRFFFQkN3VUFNQlV4RXpBUkJnTlYKQkFNTUNtdDFZbVZ5Ym1WMFpYTXdJQmNOTVRrd09ESTVNRFEwTmpVMVdoZ1BNakV4T1RBNE1EVXdORFEyTlRWYQpNQlV4RXpBUkJnTlZCQU1NQ210MVltVnlibVYwWlhNd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFDMWZncTR3QlZLa01kVGppakZUUXpVUzN1ejJPaFdxSUxhL3NmZHI5a3NJR2NmY0sxN0hIaTIKa3FsVUcrajNNWjV6cks3SE1vY0doTzJaK2dOR2dSVEd3OUFsVTlhVDlyS0s2OU5nYkJaWWREc0Eydk5wZHMzWApMaDlFbnV4NmY0aHdVak5JSDlzbWFreFJSTndKSEQwQS8wR3lpeVhPdyt5ZHl0OVk1YXNabzlOcHZiWWwycTBpCmVSSFlZRmpSY3hUU29YMVVzME43ZSs5NlBVeW82dFNmSnZGSjZNdDlaWTF5MjhtS3ZtV3BYbDlIamh0M01IVTAKUldGQWxzNWNWTHNGYjZQYU0rT3lINS9XU3o3VWIvSjhmbTcwMTI3bTJVNlR6cnE4bWJ3QTJSUHJ4T0E1N2RWbwpYUmVLSGhTNVhZRkVDTTFPY3BSVEtXLzZXUVd3Z1IvM0FnTUJBQUdqSXpBaE1BOEdBMVVkRXdFQi93UUZNQU1CCkFmOHdEZ1lEVlIwUEFRSC9CQVFEQWdLa01BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQTY4d2xWN1lKVEpWVUoKc05OY0hsRHRjUnh0OFFwbHFKNEpsaXRoVjlicEZKeTd4YlIrMDdDTWQ2a2FJUnd4QVRWeFdEMFdPVlNSb010ZAozampkeGdvbkZxVm9IR3VEWDVTcEFSRk5vR0lSSnI0Y2dlL3dwNVZnMk1ZeGpLZWhUL0xndGlBV3BWOGhOZmhMCkxBY044bHorZ2xnQldjN1BCTmQxaDcwcU1XeXZuMWpCbnAvemtEL0NIeWJDSEFoY1dqRlhQMnhzdDhCZUNOdXEKc2xrUlZRNEdaVzRpVGlYaUJSN1ZhVUJ5ZWZoTnZFY1hEc1VzNVJhOUxaL1pXd01aQ0Q0NVV6dEZvTUwxRUw5VQptUnBJcUJhSUVSYnN3NUw2K3lSVjJ4Zm9QekFwZGIxVnN3VUlaYTlJU1JsMTdJc2xFd1kyTW9YOXBUU1lYNWk2CkxPbkR3cTg4Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://127.0.0.1:8443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: coderaction
  name: coderaction
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: coderaction
  user:
    token: eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJja2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiY2thLTEyMDItc2EtdG9rZW4tY2YyOW0iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiY2thLTEyMDItc2EiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIzZGE2NDQ4Yi03ZDE3LTRjYWUtYTFjYS01YjNiMTkwM2I4NzciLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6Y2thOmNrYS0xMjAyLXNhIn0.mLss0mZ9U3sjFC3bZZEzBfhBdXXLXXxzXztDd0gg6lpz-0s2ZoYf_g7-peujVWhg8_K10Ac9XBu-wc0JQnUXpEMfSwrU4PNZsGzGw0ZwIbDZUj7GNfxzi4hZVEjVPPN6o_jfd6qJUlSWvwVLJ2ZDnru9kO_rsoNjyCQ2cqUY-hILL0PfP8pa1km0aQi0YaGh2NdrmnXX2GyW_mA6V092rAgRMJxA6xh2Am_7v3QNlBSvj76QsL3lzRnrVmXfB1JqsTsfCvdGpZIlCeGMx2kmI726pziqNjJpyHLYudmu6nYNcGtPXj6TgOjQ78VPIuy72ygvlmtgLpIL20dtLTmmbA
```
切换上下文(用户)：
```
kubectl config use-context kubernetes-admin@kubernetes
kubectl config use-context coderaction
```
查看当前上下文（用户）：
```
kubectl config view
```
正常来说，切换到coderaction用户下只能看到cka命名空间下的pod了
# 创建两个deployment名字分别为cka-1203-01、cka-1203-02；cka-1203-01的Pod加label：cka：cka-1203-01；cka-1203-02的Pod加label：cka：cka-1203-02；

请用利用kubectl命令label选择器查出这两个deployment，并按照创建时间排序。
答案：
```
[root@k8s-master ~]# kubectl run cka-1203-01 --image=nginx --labels="cka=cka-1203-01"
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
deployment.apps/cka-1203-01 created
[root@k8s-master ~]# kubectl run cka-1203-02 --image=nginx --labels="cka=cka-1203-02"
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
deployment.apps/cka-1203-02 created
```
查询含有key为cka的labels的deploy，并按照时间排序
```
[root@k8s-master ~]# kubectl get deploy --selector=cka --sort-by=.metadata.creationTimestamp
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
cka-1203-01   1/1     1            1           2m46s
cka-1203-02   1/1     1            1           119s
```
使用下面命令结果也是一样的
```
[root@k8s-master ~]# kubectl get deploy -l cka
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
cka-1203-01   1/1     1            1           4m13s
cka-1203-02   1/1     1            1           3m26s
[root@k8s-master ~]# kubectl get deploy --selector=cka
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
cka-1203-01   1/1     1            1           4m26s
cka-1203-02   1/1     1            1           3m39s
```
