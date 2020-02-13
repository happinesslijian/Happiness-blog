# kubeadm集群更改证书
**Note:** 本文基于使用kubeadm搭建的kubernetes集群进行讲解
## 第一步：获取证书签发信息

- 方式一：通过原有证书进行获取相关信息
  - 获取apiserver签发信息
  
    ```
    $ openssl x509 -noout -text -in /etc/kubernetes/pki/apiserver.crt
    ......
    X509v3 extensions:
        X509v3 Key Usage: critical
            Digital Signature, Key Encipherment
        X509v3 Extended Key Usage:
            TLS Web Server Authentication
        X509v3 Subject Alternative Name:
            DNS:localhost, DNS:node1, DNS:node2, DNS:node3, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc,   DNS:kubernetes.default.svc.cluster.local, IP Address:127.0.0.1, IP Address:10.96.0.1, IP Address:192.168.12.10, IP   Address:192.168.12.11, IP Address:192.168.12.12, IP Address:192.168.12.13
    ......
    ```
  
  - 从上面输出信息可知签发的DNS和IP详情
  
    ```ini
    DNS.1 = localhost
    # 各 master 节点 nodeName
    DNS.2 = node1
    DNS.3 = node2
    DNS.4 = node3
    # kubenertes svc 地址
    DNS.5 = kubernetes
    DNS.6 = kubernetes.default
    DNS.7 = kubernetes.default.svc
    # 带 dns domain 的 kubenertes svc 地址
    DNS.8 = kubernetes.default.svc.cluster.local
    IP.6 = 127.0.0.1
    # kubenertes svc 的 clusterip
    IP.5 = 10.96.0.1
    # api-server VIP 地址
    IP.4 = 192.168.12.10
    # 各 master 节点 IP
    IP.1 = 192.168.12.11
    IP.2 = 192.168.12.12
    IP.3 = 192.168.12.13
    ```

- 方式二：自行统计各项信息

  - 在创建证书之前需要获取到以下信息，在签发证书的时候会用到它：
    - 各master节点IP
    - 各master节点nodeName
    - 如果有设置apiserver负载均衡则需要VIP，否则请忽略
    - kubernetes集群dns domain
    - kubenertes.default.svc的clusterip
   
  - 本文以下面集群信息为例：
  
    - 节点信息：
    
        **nodeName**|**ip**|**relo**
        :-----:|:-----:|:-----:
        slb  |192.168.12.10|slb
        node1|192.168.12.11|master
        node2|192.168.12.12|master
        node3|192.168.12.13|master
        node4|192.168.12.14|worker
        node5|192.168.12.15|worker
  
    - 获取kubernetes dns domain：
  
        ```bash
        # CoreDNS 查看方法
        $ kubectl get cm -n kube-system coredns -o yaml | grep kubernetes
        kubernetes cluster.local in-addr.arpa ip6.arpa {
        # 由以上输出可知dns domain为 cluster.local
  
        # kube-dns 查看方法
        $ kubectl get deployment -n kube-system kube-dns -o yaml | grep domain
        - --domain=cluster.local.
        # 由以上输出可知dns domain为 cluster.local
        ```
  
    - kubernetes apiserver clusterip
  
      ```bash
      $ kubectl get svc kubernetes -n default
      NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
      kubernetes   ClusterIP   10.96.0.1      <none>        443/TCP   280d
      # 由结果可知apiserver clusterip
      ```

> 同理获取etcd集群证书签发的DNS和IP详情，默认etcd证书路径为`/etc/kubernetes/pki/etcd`

## 第二步：创建证书

**Note:** 我们只需要在一个节点上进行证书生成，生成的证书分发到其他节点即可

---

- 创建CA服务端证书签名请求配置文件`openssl.conf`，内容如下，注意替换`alt_names_cluster`、`alt_names_etcd`域中的值

  ```
  [ req ]
  default_bits = 2048
  default_md = sha256
  distinguished_name = req_distinguished_name

  [req_distinguished_name]

  [ v3_ca ]
  basicConstraints = critical, CA:TRUE
  keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign

  [ v3_req_server ]
  basicConstraints = CA:FALSE
  keyUsage = critical, digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth

  [ v3_req_client ]
  basicConstraints = CA:FALSE
  keyUsage = critical, digitalSignature, keyEncipherment
  extendedKeyUsage = clientAuth

  [ v3_req_apiserver ]
  basicConstraints = CA:FALSE
  keyUsage = critical, digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names_cluster

  [ v3_req_etcd ]
  basicConstraints = CA:FALSE
  keyUsage = critical, digitalSignature, keyEncipherment
  extendedKeyUsage = serverAuth, clientAuth
  subjectAltName = @alt_names_etcd

  [ alt_names_cluster ]
  DNS.1 = localhost
  DNS.2 = node1
  DNS.3 = node2
  DNS.4 = node3
  DNS.5 = kubernetes
  DNS.6 = kubernetes.default
  DNS.7 = kubernetes.default.svc
  DNS.8 = kubernetes.default.svc.cluster.local
  IP.1 = 127.0.0.1
  IP.2 = 10.96.0.1
  IP.3 = 192.168.12.10
  IP.4 = 192.168.12.11
  IP.5 = 192.168.12.12
  IP.6 = 192.168.12.13

  [ alt_names_etcd ]
  DNS.1 = localhost
  DNS.2 = node1
  DNS.3 = node2
  DNS.4 = node3
  IP.1 = 127.0.0.1
  IP.2 = 0:0:0:0:0:0:0:1
  IP.3 = 192.168.12.11
  IP.4 = 192.168.12.12
  IP.5 = 192.168.12.13
  ```

- 创建集群 key 与 CA
  - 将要创建的 CA

    | **路径**               | **Common Name**           | **描述**       |
    |------------------------|---------------------------|--------------------------------|
    | ca.crt,key             | kubernetes                | Kubernetes general CA          |
    | etcd/ca.crt,key        | kubernetes                | For all etcd-related functions |
    | front-proxy-ca.crt,key | kubernetes                | For the front-end proxy        |

  - 要注意 CA 中 CN(Common Name) 与 O(Organization) 等内容是会影响Kubernetes组件认证的
    - CA (Certificate Authority) 是自签名的根证书，用来签名后续创建的其它证书
    - CN (Common Name), apiserver 会从证书中提取该字段作为请求的用户名 (User Name)
    - O (Organization), apiserver 会从证书中提取该字段作为请求用户所属的组 (Group)
  
  > 一般CA根证书有效期为10年，若举例过期时间还长，可跳过本节操作，命令中的`3650`为3650天，即证书有效期。

  - kubernetes-ca
      ```
      openssl genrsa -out ca.key 2048
      openssl req -x509 -new -nodes -key ca.key \
        -subj "/CN=kubernetes" -config openssl.conf \
        -extensions v3_ca -out ca.crt -days 3560
      ```
  - etcd-ca
      ```
      mkdir -p etcd
      openssl genrsa -out etcd/ca.key 2048
      openssl req -x509 -new -nodes -key etcd/ca.key \
        -subj "/CN=kubernetes" -config openssl.conf \
        -extensions v3_ca -out etcd/ca.crt -days 3560
      ```

  - front-proxy-ca
    ```
    openssl genrsa -out front-proxy-ca.key 2048
    openssl req -x509 -new -nodes -key front-proxy-ca.key \
      -subj "/CN=kubernetes" -config openssl.conf \
      -extensions v3_ca -out front-proxy-ca.crt -days 3560
    ```

- 创建 Certificates
  - 将要创建的 Certificates

    | **Name**                    | **Key**                      | **Certificates**            | **Common Name**                |**Organization**|
    |-----------------------------|------------------------------|-----------------------------|--------------------------------|----------------|
    | etcd/server                 | etcd/server.key              | etcd/server.crt             | master                         |                |
    | etcd/peer                   | etcd/peer.key                | etcd/peer.crt               | master                         |                |
    | etcd/healthcheck-client     | etcd/healthcheck-client.key  | etcd/healthcheck-client.crt | kube-etcd-healthcheck-client   | system:masters |
    | apiserver-etcd-client       | apiserver-etcd-client.key    | apiserver-etcd-client.crt   | kube-apiserver-etcd-client     | system:masters |
    | apiserver                   | apiserver.key                | apiserver.crt               | kube-apiserver                 |                |
    | apiserver-kubelet-client    | apiserver-kubelet-client.key | apiserver-kubelet-client.crt| kube-apiserver-kubelet-client  | system:masters |
    | front-proxy-client          | front-proxy-client.key       | front-proxy-client.crt      | front-proxy-client             |                |
    | kube-scheduler              | kube-scheduler.key           | kube-scheduler.crt          | system:kube-scheduler          |                |
    | sa(kube-controller-manager) | sa.key(sa.pub)               | kube-controller-manager.crt | system:kube-controller-manager |                |
    | admin(kubectl)              | admin.key                    | admin.crt                   | kubernetes-admin               | system:masters |
    | kubelet                     | kubelet.key                  | kubelet.crt                 | system:node:master             | system:nodes   |



 >mkdir etcd
 cp /etc/kubernetes/pki/etcd/*.key  etcd/
 cp /etc/kubernetes/pki/etcd/ca.crt etcd/
  - etcd/server
      ```sh
      ~~openssl genrsa -out etcd/server.key 2048~~
      openssl req -new -key etcd/server.key \
        -subj "/CN=master" -out etcd/server.csr
      openssl x509 -in etcd/server.csr -req -CA etcd/ca.crt \
        -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd \
        -extfile openssl.conf -out etcd/server.crt -days 3560
      ```

  - etcd/peer
      ```
      ~~openssl genrsa -out etcd/peer.key 2048~~
      openssl req -new -key etcd/peer.key \
        -subj "/CN=master" -out etcd/peer.csr
      openssl x509 -in etcd/peer.csr -req -CA etcd/ca.crt \
        -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd \
        -extfile openssl.conf -out etcd/peer.crt -days 3560
      ```
  
  - etcd/healthcheck-client
      ```
      ~~openssl genrsa -out etcd/healthcheck-client.key 2048~~
      openssl req -new -key etcd/healthcheck-client.key \
        -subj "/CN=kube-etcd-healthcheck-client/O=system:masters" \
        -out etcd/healthcheck-client.csr
      openssl x509 -in etcd/healthcheck-client.csr -req -CA etcd/ca.crt \
        -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd \
        -extfile openssl.conf -out etcd/healthcheck-client.crt -days 3560
      ```

  >cp /etc/kubernetes/pki/*.key .
    cp /etc/kubernetes/pki/ca.crt .
    cp /etc/kubernetes/pki/front-proxy-ca.crt .
  - apiserver-etcd-client
      ```
      ~~openssl genrsa -out apiserver-etcd-client.key 2048~~
      openssl req -new -key apiserver-etcd-client.key \
        -subj "/CN=kube-apiserver-etcd-client/O=system:masters" \
        -out apiserver-etcd-client.csr
      openssl x509 -in apiserver-etcd-client.csr -req -CA etcd/ca.crt \
        -CAkey etcd/ca.key -CAcreateserial -extensions v3_req_etcd \
        -extfile openssl.conf -out apiserver-etcd-client.crt -days 3560
      ```

  - apiserver
      ```
      ~~openssl genrsa -out apiserver.key 2048~~
      openssl req -new -key apiserver.key \
        -subj "/CN=kube-apiserver" -config openssl.conf \
        -out apiserver.csr
      openssl x509 -req -in apiserver.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -extensions v3_req_apiserver \
        -extfile openssl.conf -out apiserver.crt -days 3560
      ```

  - apiserver-kubelet-client
      ```
      ~~openssl genrsa -out apiserver-kubelet-client.key 2048~~
      openssl req -new -key apiserver-kubelet-client.key \
        -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" \
        -out apiserver-kubelet-client.csr
      openssl x509 -req -in apiserver-kubelet-client.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -extensions v3_req_client \
        -extfile openssl.conf -out apiserver-kubelet-client.crt -days 3560
      ```

  - front-proxy-client
      ```
      ~~openssl genrsa -out front-proxy-client.key 2048~~
      openssl req -new -key front-proxy-client.key \
        -subj "/CN=front-proxy-client" \
        -out front-proxy-client.csr
      openssl x509 -req -in front-proxy-client.csr -CA front-proxy-ca.crt -CAkey front-proxy-ca.key \
        -CAcreateserial -extensions v3_req_client \
        -extfile openssl.conf -out front-proxy-client.crt -days 3560
      ```

  - kube-scheduler
      ```
      openssl genrsa -out kube-scheduler.key 2048
      openssl req -new -key kube-scheduler.key \
        -subj "/CN=system:kube-scheduler" \
        -out kube-scheduler.csr
      openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -extensions v3_req_client \
        -extfile openssl.conf -out kube-scheduler.crt -days 3560
      ```
>cp /etc/kubernetes/pki/sa.pub .
  - sa(kube-controller-manager)
      ```
    ~~openssl genrsa -out sa.key 2048~~
     ~~openssl rsa -in sa.key -pubout -out sa.pub~~
      openssl req -new -key sa.key \
        -subj "/CN=system:kube-controller-manager" \
        -out kube-controller-manager.csr
      openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key \
        -CAcreateserial -extensions v3_req_client \
        -extfile openssl.conf -out kube-controller-manager.crt -days 3560
      ```

  - admin(kubectl)
    ```
    openssl genrsa -out admin.key 2048
    openssl req -new -key admin.key \
      -subj "/CN=kubernetes-admin/O=system:masters" \
      -out admin.csr
    openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key \
      -CAcreateserial -extensions v3_req_client \
      -extfile openssl.conf -out admin.crt -days 3560 
    ```

  - kubelet
    ```
    openssl genrsa -out kubelet.key 2048
    # 此处为 master 节点 nodeName，每个 master 生成对应的证书
    openssl req -new -key kubelet.key \
      -subj "/CN=system:node:node1/O=system:nodes" \
      -out kubelet.csr
    openssl x509 -req -CA ca.crt -CAkey ca.key \
      -CAcreateserial -extensions v3_req_client \
      -extfile openssl.conf -days 3560 -in kubelet.csr -out kubelet.crt
    ```

## 第三步：生成kubernetes各组件配置文件并应用

- 所要生成的配置文件列表

  | **配置文件名称**          | **组件证书文件名称**           | **组件秘钥文件名称**      | **根证书文件名称** |
  |-------------------------|-----------------------------|-------------------------|------------------|
  | admin.conf(kubectl)     | admin.crt                   | admin.key               | ca.crt           |
  | kubelet.conf            | kubelet.crt                 | kubelet.key             | ca.crt           |
  | scheduler.conf          | kube-scheduler.crt          | kube-scheduler.key      | ca.crt           |
  | controller-manager.conf | kube-controller-manager.crt | sa.key                  | ca.crt           |

  - 操作前请先备份原有配置文件
  - 除了`kubelet.conf`文件需注意配置为对应节点的nodeName，其余配置文件可通用
  - 以下操作请先在一台 master 节点上操作确认没有问题后再进行配置其他节点
  - –certificate-authority：指定根证书
  - –client-certificate、–client-key：指定组件证书及秘钥
  - –embed-certs=true：将组件证书内容嵌入到生成的配置文件中(不加时，写入的是证书文件路径)

- admin.conf(kubectl)
    ```
    KUBE_APISERVER="https://192.168.12.10:6443"
    CLUSTER_NAME="kubernetes"
    KUBE_USER="kubernetes-admin"
    KUBE_CERT="admin"
    KUBE_CONFIG="admin.conf"
    
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置客户端认证参数
    kubectl config set-credentials ${KUBE_USER} \
      --client-certificate=${KUBE_CERT}.crt \
      --client-key=${KUBE_CERT}.key \
      --embed-certs=true \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置上下文参数
    kubectl config set-context ${KUBE_USER}@${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=${KUBE_USER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置当前使用的上下文
    kubectl config use-context ${KUBE_USER}@${CLUSTER_NAME} --kubeconfig=${KUBE_CONFIG}
    
    # 查看生成的配置文件
    kubectl config view --kubeconfig=${KUBE_CONFIG}
    ```
>cp /etc/kubernetes/kubelet.conf .
- kubelet.conf（注意配置对应的nodeName）
    ```
    KUBE_APISERVER="https://192.168.12.10:6443"
    CLUSTER_NAME="kubernetes"
    # 此处为 master 节点 nodeName，每个 master 生成对应的 kubelet.conf
    KUBE_USER="system:node1:master"
    KUBE_CERT="kubelet"
    KUBE_CONFIG="kubelet.conf"
    
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置客户端认证参数
    kubectl config set-credentials ${KUBE_USER} \
      --client-certificate=${KUBE_CERT}.crt \
      --client-key=kubelet.key \
      --embed-certs=true \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置上下文参数
    kubectl config set-context ${KUBE_USER}@${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=${KUBE_USER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置当前使用的上下文
    kubectl config use-context ${KUBE_USER}@${CLUSTER_NAME} --kubeconfig=${KUBE_CONFIG}
    
    # 查看生成的配置文件
    kubectl config view --kubeconfig=${KUBE_CONFIG}
    ```

- scheduler.conf
    ```
    KUBE_APISERVER="https://192.168.12.10:6443"
    CLUSTER_NAME="kubernetes"
    KUBE_USER="system:kube-scheduler"
    KUBE_CERT="kube-scheduler"
    KUBE_CONFIG="scheduler.conf"
    
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置客户端认证参数
    kubectl config set-credentials ${KUBE_USER} \
      --client-certificate=${KUBE_CERT}.crt \
      --client-key=${KUBE_CERT}.key \
      --embed-certs=true \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置上下文参数
    kubectl config set-context ${KUBE_USER}@${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=${KUBE_USER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置当前使用的上下文
    kubectl config use-context ${KUBE_USER}@${CLUSTER_NAME} --kubeconfig=${KUBE_CONFIG}
    
    # 查看生成的配置文件
    kubectl config view --kubeconfig=${KUBE_CONFIG}
    ```

- controller-manager.conf
    ```
    KUBE_APISERVER="https://192.168.12.10:6443"
    CLUSTER_NAME="kubernetes"
    KUBE_USER="system:kube-controller-manager"
    KUBE_CERT="kube-controller-manager"
    KUBE_CONFIG="controller-manager.conf"
    
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=ca.crt \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置客户端认证参数
    kubectl config set-credentials ${KUBE_USER} \
      --client-certificate=${KUBE_CERT}.crt \
      --client-key=sa.key \
      --embed-certs=true \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置上下文参数
    kubectl config set-context ${KUBE_USER}@${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=${KUBE_USER} \
      --kubeconfig=${KUBE_CONFIG}
    
    # 设置当前使用的上下文
    kubectl config use-context ${KUBE_USER}@${CLUSTER_NAME} --kubeconfig=${KUBE_CONFIG}
    
    # 查看生成的配置文件
    kubectl config view --kubeconfig=${KUBE_CONFIG}
    ```
```
  rm -rf *.csr
  cp -r /etc/kubernetes/ /etc/kubernetes.bak
  cd /etc/kubernetes/pki
 \cp -rf /root/key/* .
  cd ..
  \cp pki/*.conf .
   rm -rf openssl.conf
```
- 应用配置
  - 重启 Docker 和 Kubelet
  - 查看三个kubernetes组件（kubelet，controller-manager，scheduler）的日志，确认是否还有证书过期报错信息。

- Worker节点证书更新操作
  - 停止docker和kubelet
    ```
    systemctl stop docker && systemctl stop kubelet
    ```
  - 删除`kubelet.conf`文件，文件一般在`/etc/kubernetes`目录下。
  - ~~编辑`bootstrap-kubelet.conf`文件（文件一般在`/etc/kubernetes`目录下），修改`certificate-authority-data`内容，与master节点中的`admin.conf`文件的该区域内容相同。~~
  - 备份后删除该目录下的文件`rm -rf /var/lib/kubelet/pki`
  - 重启所有节点docker和kubelet

    ```
    systemctl restart docker && systemctl restart kubelet
    ```

### 重启服务
- 将全部kube-proxy重启
- 将全部网络插件重启（比如：flannel）

### 更新权限更新token
- ~~cp /etc/kubernetes/admin.conf  ~/.kube/config~~
- ~~kubeadm token list~~
- ~~kubeadm token create --ttl=0~~
- ~~kubeadm token list~~
把获取到的token更新到node节点/etc/kubernetes/`bootstrap-kubelet.conf`
重启node节点kubelet
