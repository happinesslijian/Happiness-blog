### 摘要
在这片文章中，我将展示如何在Google Chrome上打开kubernetes dashboard。本文不叙述如何安装搭建docker和kubernetes，有关详情请上网查阅！
***
很多小伙伴们在自己搭建完kubernetes在通过谷歌浏览器访问dashboard的时候会有如下提示
![ab3b9844cb2f5307.png](https://i.loli.net/2020/02/13/adOMb6TB7rLWNhQ.png)

据我本人所测试目前只有火狐浏览器支持打开如下图
![7fe34530442c4ed8.png](https://i.loli.net/2020/02/13/hVyP4c3IMil1FHU.png)
***
这个问题很困扰使用者，那么我们就来看看如何通过谷歌浏览器打开自己部署的kubernetes UI界面
```sh
mkdir key && cd key
#生成证书
openssl genrsa -out dashboard.key 2048 
openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=192.168.246.200'
openssl x509 -req -in dashboard.csr -signkey dashboard.key -out dashboard.crt 
#删除原有的证书secret
kubectl delete secret kubernetes-dashboard-certs -n kube-system
#创建新的证书secret
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kube-system
#查看pod
kubectl get pod -n kube-system
#重启pod
kubectl delete pod <pod name> -n kube-system
```
完成以上操作之后我们重新刷新一下谷歌浏览器
这个时候我们就可以通过谷歌浏览器打开kubernetes dashboard了
![6f0cf3df9c871cff.png](https://i.loli.net/2020/02/13/3e2QdWxfR5wsBTJ.png)




