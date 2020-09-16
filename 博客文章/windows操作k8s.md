# windows操作k8s
1. 下载对应版本的kubectl.exe
```
https://storage.googleapis.com/kubernetes-release/release/v1.16.8/bin/windows/amd64/kubectl.exe
```
2. 把kubectl.exe放在cd C:\Users\$yourname的目录下
3. 可选(可是使用git bash来操作，也可以使用CMD来操作)
```
#git下载地址
https://www.git-scm.com/download/
```
4. 把k8s服务端的/root/.kube/config下载到windows
```
#以管理员身份运行CMD,在CMD内操作

cd C:\Users\$yourname

mkdir .\.kube

copy C:\Users\$yourname\Desktop\config .kube
```
5. 操作
```
C:\Users\$yourname>kubectl get node
NAME     STATUS   ROLES         AGE   VERSION
master   Ready    etcd,master   16h   v1.16.8
node1    Ready    worker        16h   v1.16.8
node2    Ready    worker        16h   v1.16.8
```
6. 修改CMD起始位置
打开CMD后默认是`C:\Windows\System32`目录,在该目录下不能操作kubectl
所以我们将`命令提示符`路径进行更换
- 进入`C:\Users\$yourname\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\System Tools`
- 右键`命令提示符` `属性`
- 快捷方式`起始位置`修改为`C:\Users\$yourname`
- 重新打开CMD  发现目录已经更换为`C:\Users\$yourname>`