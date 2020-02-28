## 使用常规清单安装
> 注意：从cert-manager v0.11.0开始，Kubernetes的最低支持版本是v1.12.0。仍在运行Kubernetes v1.11或更低版本的用户应在安装cert-manager之前升级到受支持的版本。
创建一个名称空间以在其中运行cert-manager
```
kubectl create namespace cert-manager
```
我们可以继续安装cert-manager。所有资源（CustomResourceDefinitions，cert-manager和webhook组件）都包含在单个YAML清单文件中：
```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.13.1/cert-manager.yaml
```
> 注意：如果您正在运行Kubernetes v1.15或更低版本，则需要在该命令上方添加该 --validate=false标志kubectl apply，否则您将收到与x-kubernetes-preserve-unknown-fieldscert-manager CustomResourceDefinition资源中的字段 有关的验证错误 。这是一个良性错误，由于kubectl执行资源验证的方式而发生
## 使用Helm安装
部署前需要一些 crd
```
$ kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.1/deploy/manifests/00-crds.yaml
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
```
# Helm v3+
    helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v0.13.1
# Helm v2
    helm install \
    --name cert-manager \
    --namespace cert-manager \
    --version v0.13.1 \
    jetstack/cert-manager
```
## 验证安装
你可以通过检查cert-manager运行Pod的名称空间来验证它是否已正确部署：
```
kubectl get pods --namespace cert-manager

NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6f9d54fdc7-z9zvs              1/1     Running   0          3h26m
cert-manager-cainjector-6b6c7955f4-f5mcr   1/1     Running   0          3h26m
cert-manager-webhook-84954f5587-6nbks      1/1     Running   0          3h26m
```
>如果出现问题可以查看[官方指南](https://cert-manager.io/docs/faq/)

## 创建ingress  
`vim ingress.nginx.yaml`
```
apiVersion: extensions/v1beta1                            
kind: Ingress
metadata:
  name: solo-ingress
  namespace: solo
  annotations:
    kubernietes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - blog.k8s.fit
    secretName: solo-tls
  rules:
  - host: blog.k8s.fit
    http:
      paths:
      - path: /
        backend:
          serviceName: solo
          servicePort: 8080
---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: 15xxxxxxxx0@163.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: solo
  namespace: solo
spec:
  secretName: solo-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  duration: 2160h
  renewBefore: 360h
  keyEncoding: pkcs1
  dnsNames:
  - blog.k8s.fit
```
## 配置详解:
- ClusterIssuer  
  `cret-manager` 提供两种自定义签发资源对象。`Issuer` 只能用来签发自己所在 `namespace` 下的证书，`ClusterIssuer` 可以签发任意 `namespace` 下的证书。
  - `metadata.name` 是我们创建的签发机构的名称，后面我们创建证书的时候会引用它
  - `spec.acme.email` 是你自己的邮箱，证书快过期的时候会有邮件提醒，不过 cert-manager 会利用 acme 协议自动给我们重新颁发证书来续期
  - `spec.acme.server` 是 acme 协议的服务端，我们这里用 Let’s Encrypt，这个地址就写死成这样就行
  - `spec.acme.privateKeySecretRef` 指示此签发机构的私钥将要存储到哪个 Secret 对象中，名称不重要
  - `spec.acme.solvers.http01` 这里指示签发机构使用 HTTP-01 的方式进行 acme 协议 (还可以用 DNS 方式，acme 协议的目的是证明这台机器和域名都是属于你的，然后才准许给你颁发证书)
- Certficate  
`ClusterIssuer` 创建成功后，就可以申请免费的证书了,cert-manager 给我们提供了 `Certificate` 这个用于生成证书的自定义资源对象，它必须局限在某一个 `namespace` 下，证书最终会在该 `namespace` 下以 `Secret` 的资源对象存储。  
  - `spec.secretName` 指示证书最终存到哪个 Secret 中
  - `spec.issuerRef.kind` 值为 ClusterIssuer 说明签发机构不在本 namespace 下，而是在全局
  - `spec.issuerRef.name` 我们创建的签发机构的名称 (ClusterIssuer.metadata.name)
  - `spec.dnsNames` 指示该证书的可以用于哪些域名
>具体的详见[官方API文档](https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1alpha2.CertificateSpec)  
>**注意!** 请确保域名已经购买，是自己的。并且已经解析在公网上。否则第三方证书会申请失败!
## 创建ingress.nginx.yaml
```
kubectl apply -f ingress.nginx.yaml
```
查看 certificate和clusterissuer 创建状态
```
$ kubectl get certificate,clusterIssuer -n solo
NAME                               READY   SECRET     AGE
certificate.cert-manager.io/solo   True    solo-tls   139m

NAME                                             READY   AGE
clusterissuer.cert-manager.io/letsencrypt-prod   True    139m
```
看到上面certificate和clusterissuer都是True状态即可！至此cert-manager部署完毕
## 验证是否生效
![](https://imgkr.cn-bj.ufileos.com/f1b6ddfb-f366-463c-be28-79645a473e8c.png)
>如果创建失败请参照[官方常见问题](https://cert-manager.io/docs/faq/)  
[cert-manager 官网](https://cert-manager.io/docs/)
## 总结
> 该项目就是自动给ingress创建https,并自动续期！  
确保如下几点:
 - 域名是你自己的
 - 已经做完域名备案
 - 解析在公网上
## 番外篇
如果你是使用frp进行内网穿透,frpc配置如下:  
`vim frpc.ini`
```
[solo-https]
type = https
local_ip = 192.168.0.158
local_port = 30443
custom_domains = blog.k8s.fit
use_compression = true
use_encryption = true

[solo-http]
type = http
local_ip = 192.168.0.158
local_port = 30080
custom_domains = blog.k8s.fit
use_compression = true
use_encryption = true

[nextcloud-https]
type = https
local_ip = 192.168.0.158
local_port = 30443
custom_domains = nextcloud.k8s.fit
use_compression = true
use_encryption = true

[nextcloud-http]
type = http
local_ip = 192.168.0.158
local_port = 30080
custom_domains = nextcloud.k8s.fit
use_compression = true
use_encryption = true
```
> **注意：** **`local_port`** 并不是你应用所映射出来的NodePort端口  
说明：**`local_port`** 是 **`ingress-controller`** 映射出的端口,也就是 **`集群唯一入口`**  
如下： 
```
$ kubectl get svc -n ingress-controller
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP                   PORT(S)                      AGE
ingress-nginx   NodePort   10.244.69.211   192.168.0.158,192.168.0.159   80:30080/TCP,443:30443/TCP   97d
```
>说明：同时把http和https协议暴露出来,根据ingress的官方说明只要有`tls`参数存在,就会自动从http跳转到https 当然你也可以使用如下参数进行强制跳转:
```
apiVersion: extensions/v1beta1                            
kind: Ingress
metadata:
  ···
  annotations:
    kubernietes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ···
```