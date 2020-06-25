# 用户名密码方式登录Kubernetes-Dashboard

![](https://imgkr.cn-bj.ufileos.com/4a22cd9f-9197-4b07-826f-ffc46445f53c.png)
背景：默认安装完k8s集群和Dashboard之后都是使用token登录的,这样使用起来不是很方便,每次登录还要找到token才能登录。
本片文章使用用户和密码方式进行登录！

### 环境介绍
|集群环境|集群版本|搭建方式|dashboard的版本|
|:--:|:--:|:--:|:--:|
|master|v1.16.8|kubeadm|kubernetesui_dashboard:v2.0.0-rc6|
|node1|v1.16.8|kubeadm|kubernetesui_dashboard:v2.0.0-rc6|
|node2|v1.16.8|kubeadm|kubernetesui_dashboard:v2.0.0-rc6|

### 注意事项：
如果你的环境内不止一个master,那basic-auth-file这个文件要在每一个master上生成,并保证路径及内容和其他master一致！并且每个master都要修改kube-apiserver.yaml文件！

- 创建用户文件
  - 解析：
    user,password,userID
    userID不可重复
```
echo 'admin,admin,1' > /etc/kubernetes/pki/basic_auth_file
```
- 修改配置
```
vim /etc/kubernetes/manifests/kube-apiserver.yaml
# 增加如下参数
- --basic-auth-file=/etc/kubernetes/pki/basic_auth_file
```
- 重启api-server
```
[root@master manifests]# pwd
/etc/kubernetes/manifests
[root@master manifests]# mv ./kube-apiserver.yaml ../
[root@master manifests]# mv ../kube-apiserver.yaml ./
```
- 更新配置
```
kubectl apply -f /etc/kubernetes/manifests/kube-apiserver.yaml
```
- 将用户与权限绑定
```
kubectl create clusterrolebinding  login-on-dashboard-with-cluster-admin  --clusterrole=cluster-admin --user=admin
```
- 查看绑定
```
kubectl get clusterrolebinding login-on-dashboard-with-cluster-admin
```
- 修改kubernetes-dashboard.yaml
  - 开启authentication-mode=basic配置
```
args:
  - --auto-generate-certificates
  - --namespace=kubernetes-dashboard
  - --token-ttl=43200
  - --authentication-mode=basic
```
- 更新kubernetes-dashboard
```
kubectl apply -f kubernetes-dashboard.yaml
```
- 验证
![](https://imgkr.cn-bj.ufileos.com/35dd1725-bb5d-43d4-95be-a8af54977e9f.png)
### 结束语
以上均为kubeadm方式部署的集群。如果是二进制方式部署的集群,则不用在kubernetes-dashboard.yaml文件中开启authentication-mode=basic
basic验证方式存在一个问题,就是用户名和密码要保持一致,如果用户名和密码不一致,登陆验证的时候会提示`Unauthorized (401): Invalid credentials provided`(不要问我为什么,这个问题我也不知道咋解决)
另外`/etc/kubernetes/pki/basic_auth_file`文件不会热更新,每次添加新用户之后都需要手动重启一下`api-server`一般来说,只有一个用户就够了