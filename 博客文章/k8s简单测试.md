# 概述
在容器化的时代，你是否真正的掌握了k8s呢？都说学习改变命运，很多人苦恼，我确实学了k8s了但是不知道学的怎么样。缺乏实际验（`考`）证（`试`）那么作者在这里推出这篇文章供大家学习参考。**`PS:不喜勿喷！`**
### 考试连接地址
http://ks.ctnrs.com/test.php?id=2
### 答案如下：
单选：

| 序号 | 问题 | 答案 |
| :---: | :---: | :---: |
| 1 | Kubernetes主要有哪些必备组件？ | C. apiserver/controller-manager/kubelet/kube-proxy/scheduler/etcd|
| 2 | kubelet主要功能？ | C. 容器管理 |
| 3 | kubectl是什么？ | B. 管理集群的命令行工具 |
| 4 | Deployment与Statefulset有什么区别？ | B. Deployment部署无状态应用，Statefulset部署有状态应用 |
| 5 | Pod中pause容器是做什么用的？ | C. 管理Pod网络 |
| 6 | 怎么限制Pod最大使用内存量？ | B. resources.limits.memory |
| 7 | 怎么扩容/缩容Pod副本数？ | A. kubectl scale |
| 8 | Service如何关联到对应Pod？ | B. Label |
| 9 | 以下哪个是官方维护的Ingress？ | A. Ingress Nginx |
| 10 | emptyDir数据卷类型有什么作用？ | B. 在宿主机上创建一个空目录并挂载到容器 |
| 11 | Pod删除，emptyDir数据卷会删除吗？ | A. 会 |
| 12 | hostPath数据卷类型有什么作用？ | A. 挂载宿主机目录或文件到容器 |
| 13 | RBAC是做什么的？ | A. 基于角色的访问控制 |
| 14 | ServiceAccount做什么的？ | C. 给运行的Pod中的进程提供一个身份访问Kubernetes API |
| 15 | 存储应用程序配置文件，应使用哪个资源？ | B. Configmap |

多选：

| 序号 | 问题 | 答案 |
| --- | --- | --- |
| 1 | Pod正确说法是？ | A. K8S的最小部署单元 C. Pod由一个或多个容器组成 D. 一个Pod中的多个容器在同一台Node运行 |  
| 2 | 部署应用程序常用的几种资源对象？ | A. Deployment B. Statefulset D. DaemonSet |  
| 3 | Pod启动失败通过哪些命令排查？ | A. kubectl describe pod B. kubectl logs C. kubectl get pod |  
| 4 | Service有哪几种类型？ | A. ClusterIP B. Nodeport C. Loadblanner |  
| 5 | Service有几种代理模式？ | A. Iptables B. IPVS D. Userspace |  
| 6 | Kubernetes安全机制经历哪几个阶段处理？ | B. Authentication  C. Authorization  D. Admission Control |  
| 7 | Pod健康检查支持哪几种方法？ | A. httpGet C. exec D. tcpSocket |  
| 8 | 限制Pod中容器最大可用1核(resources.limits.memory)？ | A. 1000m  D. 1 |  
| 9 | PV与PVC静态绑定依据哪几个属性？ | A. Label B. 访问模式 C. 请求容量 |  
| 10 | Node是Not Ready,可能是什么原因？ | A. kubelet没启动 B. kubelet启动时证书错误 C. kubelet无法连接apiserver D. kubelet还没有上报最新状态 | 
