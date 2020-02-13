# kubernetes-RBAC实操
- 环境准备
  - 准备test的命名空间
    - test命名空间下创建`serviceaccount`
    - test命名空间下创建`role`
    - test命名空间下创建`rolebinding`
    
```
#创建命名空间
kubectl create ns test

#在test命名空间下创建名为test的sa
kubectl create serviceaccount test -n test

#在test命名空间下创建名为test的角色,对pods,deployments,namespaces具有所有权限操作
kubectl create role test --verb=* --resource=pods,deployments,namespaces -n test

#创建rolebinding,把role和sa进行绑定
kubectl create rolebinding test --role=test --serviceaccount=test:test -n test

#获取test命名空间下的secret
kubectl get secret -n test 

#查看test命名空间下名为xxx的secret（复制token）
kubectl get secret xxx -n test -o yaml 

#base64解码
echo 上面复制的token粘贴到这里  | base64 -d
  - 复制解码后的token


#更改配置文件
vim .kube/config


contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
#添加下面的用户
- context:
    cluster: kubernetes
    user: test
  name: test

users:
- name: test
  user:
    token: 粘贴刚才复制的token
```

- 验证test角色
```
#展示当前所处的上下文
[root@k8s-master ~]# kubectl config current-context
#切换到test上下文（用户）
[root@k8s-master ~]# kubectl config use-context test
#执行命令
  - 现在会报错,因为没有default命名空间下的权限（符合预期）
[root@k8s-master ~]# kubectl get pod
#执行命令
  - 现在是正常的了，因为test上下文有test命名空间的权限,因为test命名空间没有pod,所以返回的是No resources found.（符合预期）
[root@k8s-master ~]# kubectl get pod -n test
#创建pod
[root@k8s-master ~]# kubectl run test --generator=run-pod/v1 --image=nginx -n test
```
- 创建deployment
  - 需要手动改一下role的apiGroups
```
#切回kubernetes上下文（用户）
[root@k8s-master ~]# kubectl config use-context kubernetes-admin@kubernetes
#编辑test命名空间下名为test的role
[root@k8s-master ~]# kubectl edit role test -n test

rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - '*'
- apiGroups:
  - extensions #可以看到这里默认的是extensions 替换成apps即可
  resources:
  - deployments
  verbs:
  - '*'

#再次切回test上下文（用户）
[root@k8s-master ~]# kubectl config use-context test
#创建deployment
[root@k8s-master ~]# kubectl run test --image=nginx -n test
deployment.apps/test123 created
```
