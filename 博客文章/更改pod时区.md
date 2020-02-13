# 更改pod时区
pod默认时区不是东八区,跟我们相差8小时。
[如图所示](https://i.loli.net/2019/12/05/uwxe1nThtqgPG8s.png)
这就涉及到要更改时区问题
pod更改时区一般有两种办法
### 方法一 
- 把主机的时区文件挂载到pod内：
```
[root@master ~]# cat time.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: time
  name: time
spec:
  replicas: 1
  selector:
    matchLabels:
      run: time
  template:
    metadata:
      labels:
        run: time
    spec:
      containers:
      - image: nginx
        name: time
        volumeMounts:
          - name: hosttime
            mountPath: /etc/localtime
            readOnly: true
      volumes:
      - name: hosttime
        hostPath:
          path: /etc/localtime
```
创建该yaml并验证
```
[root@master ~]# kubectl create -f time.yaml 
deployment.apps/time created
[root@master ~]# date
2019年 12月 05日 星期四 16:52:44 CST
[root@master ~]# kubectl exec -it time-766f6f974d-p65m7 sh
# date
Thu Dec  5 16:52:54 CST 2019

```
可以看到上面的时间是同步的了。但是这样需要对每个pod都进行设置，费时费力，效率不高。
### 方法二
- 使用PodPreset来预设
更改kube-apiserver,增加
`enable-admission-plugins=PodPreset`
`runtime-config=settings.k8s.io/v1alpha1=true`
```
vim /etc/kubernetes/manifests/kube-apiserver.yaml

- --enable-admission-plugins=NodeRestriction,DefaultStorageClass,PodPreset
- --runtime-config=settings.k8s.io/v1alpha1=true
```
[如图所示](https://i.loli.net/2019/12/05/Lk9X8WOAHIwcgrJ.png)
重启kube-apiserver后创建PodPreset
```
vim podpreset.yaml

apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: tz-env
spec:
  selector:
    matchLabels: #matchLabels 为空 表示应用所有容器
  env:
  - name: TZ
    value: Asia/Shanghai
```
查看已创建的podpresets
```
kubectl get podpresets
```
验证：
正常来说在后续创建的pod里都会自动注入TZ这个环境变量 如下：
[如图所示](https://i.loli.net/2019/12/05/pwuIO7QHFrEYMix.png)
再次进入容器内查看date时间
## **注意：** PodPreset是针对ns的 不是全局！
