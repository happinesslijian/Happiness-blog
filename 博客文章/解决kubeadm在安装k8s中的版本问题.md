# 解决Kubeadm在安装K8s中的版本问题

## Docker源

```
curl -o /etc/yum.repos.d/Docker-ce-Ali.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 安装特定版本

```
[root@k8s-master ~]# yum list docker-ce --showduplicates | sort -r
Repository docker-ce-stable is listed more than once in the configuration
Repository docker-ce-stable-debuginfo is listed more than once in the configuration
Repository docker-ce-stable-source is listed more than once in the configuration
Repository docker-ce-edge is listed more than once in the configuration
Repository docker-ce-edge-debuginfo is listed more than once in the configuration
Repository docker-ce-edge-source is listed more than once in the configuration
Repository docker-ce-test is listed more than once in the configuration
Repository docker-ce-test-debuginfo is listed more than once in the configuration
Repository docker-ce-test-source is listed more than once in the configuration
Repository docker-ce-nightly is listed more than once in the configuration
Repository docker-ce-nightly-debuginfo is listed more than once in the configuration
Repository docker-ce-nightly-source is listed more than once in the configuration
 * updates: mirrors.aliyun.com
Loaded plugins: fastestmirror
Installed Packages
 * extras: mirrors.aliyun.com
docker-ce.x86_64            3:18.09.7-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.6-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.5-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.4-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.3-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.2-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.1-3.el7                    docker-ce-stable 
docker-ce.x86_64            3:18.09.0-3.el7                    docker-ce-stable 
docker-ce.x86_64            18.06.3.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.06.3.ce-3.el7                   @docker-ce-stable
docker-ce.x86_64            18.06.2.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.06.1.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.06.0.ce-3.el7                   docker-ce-stable 
docker-ce.x86_64            18.03.1.ce-1.el7.centos            docker-ce-stable 
···                   略   略   略  ···········
```
> 在docker-ce-17.06.0后引入了一个新的废弃策略，但yum却错误地将此应用到了所有的docker-ce版本上，所以我们只需添加一个忽略选项即可：  
还有，在18.06版本的Docker上，不需要同时安装docker-ce-selinux  
注意格式  

```
[root@k8s ~]# yum -y install --setopt=obsoletes=0 docker-ce-18.06.3.ce 
Loaded plugins: fastestmirror
Repository docker-ce-stable is listed more than once in the configuration
Repository docker-ce-stable-debuginfo is listed more than once in the configuration
Repository docker-ce-stable-source is listed more than once in the configuration
Repository docker-ce-edge is listed more than once in the configuration
Repository docker-ce-edge-debuginfo is listed more than once in the configuration
Repository docker-ce-edge-source is listed more than once in the configuration
Repository docker-ce-test is listed more than once in the configuration
Repository docker-ce-test-debuginfo is listed more than once in the configuration
Repository docker-ce-test-source is listed more than once in the configuration
Repository docker-ce-nightly is listed more than once in the configuration
Repository docker-ce-nightly-debuginfo is listed more than once in the configuration
Repository docker-ce-nightly-source is listed more than once in the configuration
Loading mirror speeds from cached hostfile
Resolving Dependencies
--> Running transaction check
---> Package docker-ce.x86_64 0:18.06.3.ce-3.el7 will be installed
--> Processing Dependency: libltdl.so.7()(64bit) for package: docker-ce-18.06.3.ce-3.el7.x86_64
--> Running transaction check
---> Package libtool-ltdl.x86_64 0:2.4.2-22.el7_3 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

========================================================================================================================

#  Package                    Arch                 Version                           Repository                      Size

Installing:
 docker-ce                  x86_64               18.06.3.ce-3.el7                  docker-ce-stable                41 M
Installing for dependencies:
 libtool-ltdl               x86_64               2.4.2-22.el7_3                    base                            49 k
# Transaction Summary
Install  1 Package (+1 Dependent package)
Total download size: 41 M
Installed size: 168 M
Downloading packages:
(1/2): libtool-ltdl-2.4.2-22.el7_3.x86_64.rpm                                                    |  49 kB  00:00:00     

## (2/2): docker-ce-18.06.3.ce-3.el7.x86_64.rpm                                                     |  41 MB  00:00:05     

Total                                                                                   6.9 MB/s |  41 MB  00:00:05     
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Installing : libtool-ltdl-2.4.2-22.el7_3.x86_64                                                                   1/2 
  Installing : docker-ce-18.06.3.ce-3.el7.x86_64                                                                    2/2 
  Verifying  : libtool-ltdl-2.4.2-22.el7_3.x86_64                                                                   1/2 
  Verifying  : docker-ce-18.06.3.ce-3.el7.x86_64                                                                    2/2 
Installed:
  docker-ce.x86_64 0:18.06.3.ce-3.el7                                                           
Dependency Installed:
  libtool-ltdl.x86_64 0:2.4.2-22.el7_3                                                           
Complete!
```

## kubeadm kubectl kubelet源

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
 http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
```
yum list kubelet kubeadm kubectl --showduplicates|sort -r
```
```
[root@k8s-master ~]# yum list kubelet kubeadm kubectl  --showduplicates|sort -r
Repository docker-ce-stable is listed more than once in the configuration
Repository docker-ce-stable-debuginfo is listed more than once in the configuration
Repository docker-ce-stable-source is listed more than once in the configuration
Repository docker-ce-edge is listed more than once in the configuration
Repository docker-ce-edge-debuginfo is listed more than once in the configuration
Repository docker-ce-edge-source is listed more than once in the configuration
Repository docker-ce-test is listed more than once in the configuration
Repository docker-ce-test-debuginfo is listed more than once in the configuration
Repository docker-ce-test-source is listed more than once in the configuration
Repository docker-ce-nightly is listed more than once in the configuration
Repository docker-ce-nightly-debuginfo is listed more than once in the configuration
Repository docker-ce-nightly-source is listed more than once in the configuration
 * updates: mirrors.aliyun.com
Loading mirror speeds from cached hostfile
Loaded plugins: fastestmirror
kubelet.x86_64                       1.9.9-0                         kubernetes 
kubelet.x86_64                       1.9.8-0                         kubernetes 
kubelet.x86_64                       1.9.7-0                         kubernetes 
kubelet.x86_64                       1.9.6-0                         kubernetes 
kubelet.x86_64                       1.9.5-0                         kubernetes 
kubelet.x86_64                       1.9.4-0                         kubernetes 
kubelet.x86_64                       1.9.3-0                         kubernetes 
kubelet.x86_64                       1.9.2-0                         kubernetes 
···                ···············    略   略   略  ···········
```

## 安装特定版本
这里安装1.15版本

```
yum -y install kubeadm-1.15.0-0 kubelet-1.15.0-0 
```

验证
```
[root@k8s-master ~]# kubelet --version
Kubernetes v1.15.0
[root@k8s-master ~]# kubectl version
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.0", GitCommit:"e8462b5b5dc2584fdcd18e6bcfe9f1e4d970a529", GitTreeState:"clean", BuildDate:"2019-06-19T16:40:16Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.0", GitCommit:"e8462b5b5dc2584fdcd18e6bcfe9f1e4d970a529", GitTreeState:"clean", BuildDate:"2019-06-19T16:32:14Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
[root@k8s-master ~]# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.0", GitCommit:"e8462b5b5dc2584fdcd18e6bcfe9f1e4d970a529", GitTreeState:"clean", BuildDate:"2019-06-19T16:37:41Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
```
```
  [root@k8s ~]# kubeadm init  --apiserver-advertise-address 172.31.189.219 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=cri
[init] Using Kubernetes version: v1.15.0
[preflight] Running pre-flight checks


[WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/


[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.31.189.219]
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8s localhost] and IPs [172.31.189.219 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8s localhost] and IPs [172.31.189.219 127.0.0.1 ::1]
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 19.502141 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node k8s as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: r6npjy.59peqgwyyvp300eb
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.31.189.219:6443 --token r6npjy.59peqgwyyvp300eb \


--discovery-token-ca-cert-hash sha256:2cb56c70069e62679739cfab11fed220b3723435c499a912f0c9f5a3923e861d 
```

```
kubeadm join 192.168.0.89:6443 --token kcf3qd.ipq5xmyj02fqqqj9 \
    --discovery-token-ca-cert-hash sha256:dae5a339cedaef0b81e2e3d27997ae9d06e2e7b684af05d28c6624bf0c9d892b
```
