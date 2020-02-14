Kubernetes v1.15.0 集群的安装部署（详细版）
===============================
软硬件要求
-----

| 软硬件 | 最低配置 | 推荐配置 |
| --- | --- | --- |
| CPU 和 内存 | Master：至少2核4G | |
| Node：至少4核16G | Master：4核16G | |
| Node：根据运行的容器数量进行配置 | | |
| Linux 操作系统 | 基于 x86\_64 架构的各种Linux 发行版，Kernel 3.10 以上 | Red Hat Linux 7  
| CentOS 7 | | |
| etcd | 3.0 版本及以上 | 3.3 版本 |
| Docker | 18.03 版本及以上 | 18.09 版本 |

机器准备
----
| 角色 | 主机名称 | 内网 IP | 配置 | 系统 |
| --- | --- | --- | --- | --- |
| Master | KubernetesMaster | 192.168.0.123 | 2 核 4 G | CentOS 7.6.5 |
| Node | KubernetesNode1 | 192.168.0.122 | 2 核 4 G | CentOS 7.6.5 |
| Node | KubernetesNode2 | 192.168.0.121 | 2 核 4 G | CentOS 7.6.5 |

注：这里只是做环境测试，故只满足了官方要求的最低 2 核 2 G

部署步骤
----
使用 kubeadm 部署 kubernetes 主要有以下四个步骤：

> 1.  安装 Docker （所有主机）
> 2.  安装 Kubeadm（所有主机）
> 3.  基础环境配置（所有主机）
> 4.  创建 Kubernetes 集群
* * *
### 一. 安装 Docker（所有主机）
安装 Docker 引擎，主要执行以下步骤：
> 1.  安装 Docker 需要的一些系统工具
> 2.  设置 Docker 的 yum 仓库源
> 3.  安装并启动 Docker
> 4.  调整 Docker 部分参数（主要是配合 Kubernetes 的一些配置）
1.  安装必要的一些系统工具
```
yum install -y yum-utils device-mapper-persistent-data lvm2
```
2.  设置 Docker 的 yum 仓库源（稳定存储库）
*   官方源（二选一）：
```
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
*   阿里云源（二选一）：
```
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  
```
3.  安装并启动 Docker
```
yum install -y docker-ce
systemctl start docker && systemctl enable docker 
```
4.  调整 Docker 部分参数  
这里主要做两点调整：

*   配置国内镜像加速 (国内的各种原因，可能导致拉取镜像像蜗牛一样。。。)
*   修改 cgroup 驱动 (Docker 默认使用 cgroupfs，Kubernetes 官方推荐 systemd)
```
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
 "registry-mirrors": ["https://pcy9sknd.mirror.aliyuncs.com"],
 "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon-reload && systemctl restart docker
```
注：这里采用的是阿里云的镜像源，当然你也可以选择：中科大、网易、DaoCloud（还有个号称中国官方的源，但实测好像没什么卵用）
* * *
### 二. 安装 Kubeadm（所有主机）
安装 Kubeadm 主要有以下三个步骤：
> 1.  配置 Kubernetes 的 yum 仓库源（这里选用阿里的源，你懂的）
> 2.  安装 Kubeadm 和相关工具
> 3.  启动 Kubelet
1.  设置 Kubernetes 的 yum 仓库源
*   阿里云源（推荐）
```
tee /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
*   官方源（不推荐）
```
tee /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
```
2.  安装 Kubeadm 和相关工具
```
yum install -y kubelet kubeadm kubectl
```
3.  启动 Kubelet
```
systemctl start kubelet && systemctl enable kubelet
```
* * *

### 三. 基础环境配置（所有主机）
基础环境配置，主要执行以下步骤：
> 1.  设置各节点时间精确同步
> 2.  关闭 firewalld/iptables 防火墙
> 3.  关闭 SElinux 安全模组
> 4.  关闭 Swap 交换分区
> 5.  导入 IPVS 模块
> 6.  修改 Bridge 桥接规则
> 7.  开启 iptables 的 FORWARD 转发链
> 8.  配置 Hosts 解析
1.  设置各节点时间精确同步
```
systemctl start chronyd.service && systemctl enable chronyd.service
```
2.  关闭 firewalld 防火墙（允许 master 和 node 的网络通信）  
由于 Master 和 Node 存在大量网络交互，需对防火墙进行相关配置
*   外网环境：在防火墙上配置各组件相互通信的端口
*   内网环境：直接关闭防火墙，减少防火墙规则的维护工作
```
systemctl stop firewalld && systemctl disable firewalld
```
3.  关闭 SElinux 安全模组（让容器可以读取主机的文件系统）
```
setenforce 0 && sed -i "s/SELINUX=enforcing$/SELINUX=disabled/g" /etc/selinux/config
```
4.  关闭 Swap 交换分区（启用了 Swap，则 Qos 策略可能会失效）
```
swapoff -a && sed -i "s/\/dev\/mapper\/centos-swap/\#\/dev\/mapper\/centos-swap/g" /etc/fstab
```
5.  导入 IPVS 模块（用来为大量服务进行负载均衡）
```
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```
6.  修改 Bridge 桥接规则（部分 Docker 安装时会为我们修改，这里统一进行手动修改）
```
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF
sysctl --system
```
7.  开启 iptables 的 FORWARD 转发链（Docker 1.13 后禁用了 FORWARD 链，这可能会引起 Pod 间无法通信）
```
iptables -P FORWARD ACCEPT
sed -i '/ExecStart/a ExecStartPost=/sbin/iptables -P FORWARD ACCEPT' /usr/
lib/systemd/system/docker.service
systemctl daemon-reload
```
8.  配置 Hosts 解析（添加 k8s 所有节点的 IP 和对应主机名，否则初始化的时候会出现告警甚至错误）
```
tee /etc/hosts <<-'EOF'
::1 localhost   localhost.localdomain   localhost6  localhost6.localdomain6
127.0.0.1   localhost   localhost.localdomain   localhost4  localhost4.localdomain4
192.168.0.123 kube-master
192.168.0.122 kube-node1
192.168.0.121 kube-node2
EOF
```
9.  安装一些必要的工具（这些工具在以后的命令中会用到）
```
yum install -y ipset
yum install -y ipvsadm
yum install -y bind-utils
```
* * *
### 四. 创建 Kubernetes 集群
创建 Kubernetes 集群主要有两个步骤：
> 1.  初始化 Master 节点
> 2.  初始化 Node 节点
#### 1\. 初始化 Master 节点
初始化 Master 节点，主要有四个步骤：
> 1.  执行初始化
> 2.  复制(分发)配置文件
> 3.  安装 CNI 网络插件
> 4.  检查 Master 的 Pod 及 集群状态

1.  执行初始化  
自定义配置较少时：推荐使用 `配置参数` 的方式进行初始化  
自定义配置较多时，推荐使用 `配置文件` 的方式进行初始化：
1.  使用 `kubeadm config print init-defaults > kubeadm-init.yaml` 获取初始配置文件进行相应的自定义修改
2.  然后使用 `kubeadm init --config kubeadm-init.yaml`，通过配置文件进行初始化
*   较少自定义配置时，采用第一种方式进行初始化
```
kubeadm init --kubernetes-version=v1.15.0 \
--pod-network-cidr=<network-segment> \
--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
```
*   较多自定义配置时，采用第二种方式进行初始化
```
# 修改初始化配置文件
cat > master-init.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
 advertiseAddress: 192.168.0.123
 bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta2
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: v1.15.0
networking:
 dnsDomain: cluster.local
 podSubnet: <network-segment>
EOF

# 执行初始化
kubedam init --master-init.yaml
```
注意：  
初始化之后会安装网络插件，由于各个网络插件使用的网段不一样，  
故需对 命令中的`--pod-network-cidr=<network-segment>` 或文件中的 `podSubnet: <network-segment>` 进行自定义配置，  
Calico 的默认网段：192.168.0.0/16，Flannel 的默认网段：10.244.0.0/16

输出以下内容表示成功：
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.123:6443 --token b0syjo.7q877s663mc1rbni \
--discovery-token-ca-cert-hash
sha256:cdbcbb721002cac7a7b347295922eabe65342e111a67d7f7acce50d0d9d8f27f
// 上面一句是 Node 节点加入集群的命令，记得保存一下
```
2.  按照提示，复制配置文件到普通用户目录
*   非 root 用户
```
# 拷贝配置文件到 Master 节点
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 分发配置文件到各 Node 节点（让 Node 节点使用 `kubectl`）
scp /etc/kubernetes/admin.conf KubernetesNode1:~/.kube/config
scp /etc/kubernetes/admin.conf KubernetesNode2:~/.kube/config
# 记得在 Node 上进行授权，sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
*   root 用户
```
# 拷贝配置文件到 Master 节点
mkdir /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# 分发配置文件到各 Node 节点（让 Node 节点使用 `kubectl`）
scp /etc/kubernetes/admin.conf KubernetesNode1:/root/.kube/config
scp /etc/kubernetes/admin.conf KubernetesNode2:/root/.kube/config
```
3.  安装 CNI 网络插件
*   Flannel 插件
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
参考：Flannel Github - [README.md](https://links.jianshu.com/go?to=%255Bhttps%3A%2F%2Fgithub.com%2Fcoreos%2Fflannel%2F%255D%28https%3A%2F%2Fgithub.com%2Fcoreos%2Fflannel%2F%29)
*   Calico 插件
```
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
```
参考：Calico 官方文档 - [Quickstart for Calico on Kubernetes](https://links.jianshu.com/go?to=https%3A%2F%2Fdocs.projectcalico.org%2Fv3.8%2Fgetting-started%2Fkubernetes%2F)  
更多 CNI 插件可以参考：Kubernetes 官方文档提供的教程 - [Installing Addons](https://links.jianshu.com/go?to=https%3A%2F%2Fkubernetes.io%2Fdocs%2Fconcepts%2Fcluster-administration%2Faddons%2F)

4.  检查 Master 的 Pod 及 集群状态
*   使用 `kubectl get pod -n kube-system -o wide`，查看 Pod 状态均为 `Runing` 即可
*   使用 `kubectl get node -o wide`，查看 Node 状态为 `Ready` 表示 Master 初始化完成
* * *
#### 2\. 初始化 Node 节点
初始化 Node 节点就比较简单了，只有两步，即：
> 1.  执行初始化
> 2.  检查 Node 的 Pod 及 集群状态
1.  初始化 Node  
使用 Master 初始化时的命令进行初始化即可，Node 节点初始化后，就直接加入了集群
```
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<sha256>
```
注意：没有记录集群 join 命令的可以通过以下方式重新获取
```
sudo kubeadm token create --print-join-command --ttl=0
```
2.  检查 Node 的 Pod 及 集群状态
*   使用 `kubectl get pod -n kube-system -o wide`，查看 Pod 状态均为 `Runing` 即可
*   使用 `kubectl get node -o wide`，查看 所有节点 状态均为 `Ready` 表示 Master 初始化完成
* * *
### 五. 重置 Kubernetes 集群
在集群安装失败，或者出现一些无法解决的问题时，可以重置集群，再重新安装  
重置 Kubernetes 集群，主要的执行步骤如下：
> 1.  kubeadm 集群重置
> 2.  iptables 规则清理
> 3.  ipvs 规则清理
> 4.  kubernetes 配置文件清理
> 5.  etcd 配置清理
> 6.  cni 网络插件清理

废话不多说，直接撸代码
```
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
ipvsadm --clear
rm -rf ~/.kube
rm -rf /var/lib/etcd
ifconfig cni0 down
ip link delete cni0
ifconfig flannel.1 down
ip link delete flannel.1
rm -rf /var/lib/cni/
```
* * *

参考：  
[https://kubernetes.io/zh/docs/setup/independent/install-kubeadm/](https://links.jianshu.com/go?to=https%3A%2F%2Fkubernetes.io%2Fzh%2Fdocs%2Fsetup%2Findependent%2Finstall-kubeadm%2F)  
[https://k8smeetup.github.io/docs/reference/setup-tools/kubeadm/kubeadm-init/](https://links.jianshu.com/go?to=https%3A%2F%2Fk8smeetup.github.io%2Fdocs%2Freference%2Fsetup-tools%2Fkubeadm%2Fkubeadm-init%2F)  
[centos7使用kubeadm安装部署kubernetes 1.14 - Adrian·Ding - 博客园](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.cnblogs.com%2Fding2016%2Fp%2F10784620.html)  
[CentOS7中用kubeadm安装Kubernetes-云栖社区-阿里云](https://links.jianshu.com/go?to=https%3A%2F%2Fyq.aliyun.com%2Farticles%2F626118)
