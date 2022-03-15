# 使用Reloader实现k8s的ConfigMap和Secret的热更新
> 叙述：Configmap或Secret使用有两种方式，一种是env系统变量赋值，一种是volume挂载赋值，env写入系统的configmap是不会热更新的，而volume写入的方式支持热更新！

- 对于env环境的，必须要滚动更新pod才能生效，也就是删除老的pod，重新使用镜像拉起新pod加载环境变量才能生效。
- 对于volume的方式，虽然内容变了，但是需要我们的应用直接监控configmap的变动，或者一直去更新环境变量才能在这种情况下达到热更新的目的。

### secret挂载方式
```
# 创建secret
cat > secret.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque   #不透明
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
EOF

#使用Secret

cat > pod_use_secret.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: testredis
    image: daocloud.io/library/redis
    volumeMounts:    #挂载一个卷
    - name: foo     #这个名字需要与定义的卷的名字一致
      mountPath: "/etc/foo"  #挂载到容器里哪个目录下，随便写
      readOnly: true
  volumes:     #数据卷的定义
  - name: foo   #卷的名字这个名字自定义
    secret:    #卷是直接使用的secret。
      secretName: mysecret   #调用刚才定义的secret
EOF
```
### secret ENV方式
```
# 创建secret
cat > secret.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque   #不透明
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
EOF
# 使用Secret
cat > pod_use_secret.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: testredis
    image: mysql:5.7
    env:
    - name: MYSQL_DATABASE
	  value: mysecret
    envFrom:
    - secretRef:
        name: mysecret
EOF
```
---
### ConfigMap挂载方式
```
# 创建ConfigMap
kubectl create cm nginx-cm --from-file=nginx.conf

cat > configMap.yml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
    containers:
    - name: nginx
      image: nginx:latest
      volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: daima
          mountPath: /usr/share/nginx/html/
    restartPolicy: Always
    volumes:
      - name: config-volume
        configMap:
          name: nginx-cm
          items:
            - key: nginx.conf
              path: nginx.conf
EOF
```
### ConfigMap ENV方式
```
# 创建ConfigMap
cat > config.yml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-conf
data:
  ENV_1: "111.111.111.111"
  ENV_NAME: "test"
EOF  

cat > deployment.yml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        # 导入环境变量
        envFrom:
          # 使用configMap
          - configMapRef:
              # name为configMap中的metadata name
              name: nginx-config
EOF
```
> ConfigMap 和 Secret 是 Kubernetes 常用的保存配置数据的对象，你可以根据需要选择合适的对象存储数据。通过 Volume 方式挂载到 Pod 内的，kubelet 都会定期进行更新。但是通过环境变量注入到容器中，这样无法感知到 ConfigMap 或 Secret 的内容更新。
## reloader简介
> Reloader 可以观察 ConfigMap 和 Secret 中的变化，并通过相关的 deploymentconfiggs、 deploymentconfiggs、 deploymonset 和 statefulset 对 Pods 进行滚动升级。
### reloader安装
- helm安装
```
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm install stakater/reloader
```
- 资源清单安装
```
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
```
### 配置
- 自动更新  
reloader.stakater.com/search 和 reloader.stakater.com/auto 并不在一起工作。  
如果你在你的部署上有一个 reloader.stakater.com/auto : "true"的注释，该资源对象引用的所有configmap或secret的改变都会重启该资源，不管他们是否有 reloader.stakater.com/match : "true"的注释。
可以理解为强制更新。只要deployment有reloader.stakater.com/auto : "true"的注释 修改configmap或者secret后该deploy都会restart并加载新的configmap或者secret
```
kind: Deployment
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
spec:
  template: metadata:
```
- 指定更新  
指定一个特定的configmap或者secret，只有在我们指定的configmap或secret被改变时才会触发滚动升级，这样，它不会触发滚动升级所有配置图或秘密在部署，后台登录或状态设置中使用。  
一个指定 deployment 资源对象，在引用的configmap或者secret中，只有reloader.stakater.com/match: "true"为true才会触发更新，为false或者不进行标记，该资源对象都不会监视配置的变化而重启。
```
kind: Deployment
metadata:
  annotations:
    reloader.stakater.com/search: "true"
spec:
  template:
```

```
kind: ConfigMap
metadata:
  annotations:
    reloader.stakater.com/match: "true"
data:
  key: value
```
### 指定 cm
如果一个deployment挂载有多个cm或者的场景下，我们只希望更新特定一个cm后，deploy发生滚动更新，更新其他的cm，deploy不更新，这种场景可以将cm在deploy中指定为单个或者列表实现。

例如：一个deploy有挂载nginx-cm1和nginx-cm2两个configmap，只想nginx-cm1更新的时候deploy才发生滚动更新，此时无需在两个cm中配置注解，只需要在deploy中写入configmap.reloader.stakater.com/reload:nginx-cm1，其中nginx-cm1如果发生更新，deploy就会触发滚动更新。

如果多个cm直接用逗号隔开
```
# configmap对象
kind: Deployment
metadata:
  annotations:
    configmap.reloader.stakater.com/reload: "nginx-cm1"
spec:
  template: metadata:

# secret对象
kind: Deployment
metadata:
  annotations:
    secret.reloader.stakater.com/reload: "foo-secret"
spec:
  template: metadata:  
```
> 无需在cm或secret中添加注解，只需要在引用资源对象中添加注解即可。


参考链接：  
https://github.com/stakater/Reloader  
https://tinyurl.com/j9t3knbe  
https://mp.weixin.qq.com/s/f7W4HrX5rV2m_A7aHT8O8w  

