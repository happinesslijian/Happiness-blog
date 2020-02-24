Kubernetes安装cert-manager
## 使用常规清单安装
> 注意：从cert-manager v0.11.0开始，Kubernetes的最低支持版本是v1.12.0。仍在运行Kubernetes v1.11或更低版本的用户应在安装cert-manager之前升级到受支持的版本。
创建一个名称空间以在其中运行cert-manager
```
kubectl create namespace cert-manager
```
我们可以继续安装cert-manager。所有资源（CustomResourceDefinitions，cert-manager和webhook组件）都包含在单个YAML清单文件中：
```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.0/cert-manager.yaml
```
> 注意：如果您正在运行Kubernetes v1.15或更低版本，则需要在该命令上方添加该 --validate=false标志kubectl apply，否则您将收到与x-kubernetes-preserve-unknown-fieldscert-manager CustomResourceDefinition资源中的字段 有关的验证错误 。这是一个良性错误，由于kubectl执行资源验证的方式而发生
## 使用Helm安装
部署前需要一些 crd
```
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.0/deploy/manifests/00-crds.yaml
```
为ce​​rt-manager创建名称空间
```
kubectl create namespace cert-manager
```
添加Jetstack Helm存储库。
```
helm repo add jetstack https://charts.jetstack.io
```
更新您的本地Helm存储库缓存
```
helm repo update
```
- 安装cert-manager
  - Helm v3+
    ```  
    helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v0.13.0
    ```
  - Helm v2
    ```
    helm install \
    --name cert-manager \
    --namespace cert-manager \
    --version v0.13.0 \
    jetstack/cert-manager
    ```
## 验证安装
你可以通过检查cert-manager运行Pod的名称空间来验证它是否已正确部署：
```
kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6d5fd89bdf-k7wfn              1/1     Running   0          30m
cert-manager-cainjector-7d47d59998-mds8l   1/1     Running   2          30m
cert-manager-webhook-6559cc8549-lvpjf      1/1     Running   0          30m
```
## 创建ingress
- nginx代理配置
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-service-ingress                 
  namespace: nginx
  annotations:
    #指定使用nginx做代理
    kubernetes.io/ingress.class: "nginx"
    #关联到名为letsencrypt-prod的Issuer
    cert-manager.io/issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    #自定义域名
    - nginx.xtestx.tech
    secretName: nginx-tls
  rules:
    #自定义域名
  - host: nginx.xtestx.tech
    http:
      paths:
      - backend:
          #服务名称
          serviceName: nginx
          #服务端口
          servicePort: 80
        path: /
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-prod
  #保持和ingress处于相同的ns
  namespace: nginx
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: nginx-tls
  #保持和ingress处于相同的ns
  namespace: nginx
spec:
  secretName: nginx-tls
  duration: 2160h
  renewBefore: 360h
  dnsNames:
  #自定义域名
  - nginx.xtestx.tech
  issuerRef:
    #指定名为letsencrypt-prod的Issuer
    name: letsencrypt-prod

```
- traefik代理配置
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui-test
  namespace: kube-system
  annotations:
    #指定使用traefik做代理
    kubernetes.io/ingress.class: traefik
    #traefik开启https
    traefik.ingress.kubernetes.io/redirect-entry-point: https
    #指定名为cert-test的Issuer
    cert-manager.io/issuer: "cert-test"
spec:
  tls:
  - hosts:
    #自定义域名
    - traefik.test.com
    secretName: traefik-tls
  rules:
  #自定义域名
  - host: traefik.test.com
    http:
      paths:
      - path: /
        backend:
          #服务名称
          serviceName: traefik-web-ui
          #服务端口
          servicePort: web
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: test
  #保持和ingress处于相同的ns
  namespace: kube-system
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: traefik-test
  #保持和ingress处于相同的ns
  namespace: kube-system
spec:
  secretName: traefik-tls
  duration: 2160h
  renewBefore: 360h
  dnsNames:
  #自定义域名
  - traefik.test.com
  issuerRef:
    #指定名为test的Issuer
    name: test
```
## 验证配置是否生效
```
其状态变成True即可
kubectl get certificate nginx-tls -n nginx
NAME        READY   SECRET      AGE
nginx-tls   True    nginx-tls   51m
---
kubectl describe certificate nginx-tls -n nginx
···
Status:
  Conditions:
    Last Transition Time:  2019-11-19T04:02:13Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True #这里变成true即可
    Type:                  Ready
  Not After:               2020-02-17T04:02:13Z
···
```
## 验证是否生效
配置好hosts的前提下打开浏览器输入自定义域名  如下图：
![](https://imgkr.cn-bj.ufileos.com/3d622995-3d3e-40c9-8e87-612fabccc568.png)
## 总结
该项目就是自动给ingress创建https的,省的每个ingress都要手动搞openssl
> 保持insress、Issuer、Certificate处于相同的命名空间 \
  配置好自定义域名即可 简单易上手
