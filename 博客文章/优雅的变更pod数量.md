## 优雅的变更pod数量

#### Kubernetes Node节点每个默认允许最多创建110个Pod，有时可能会由于系统硬件的问题，从而需要控制Node节点的Pod的运行数量。

1.查看kubelet配置文件所在位置 如图：
![微信截图_20220411110511.png](https://s2.loli.net/2022/04/11/o2i4yMRPBjKC8vz.png)  
2.编辑该配置文件  
```
vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
添加如下内容：

Environment="KUBELET_NODE_MAX_PODS=--max-pods=120"
#并在启动命令尾部添加变量 $KUBELET_NODE_MAX_PODS
$KUBELET_NODE_MAX_PODS
```  
![微信截图_20220411110927.png](https://s2.loli.net/2022/04/11/Fl8qor2Kc7L5GTi.png)  
3. 重新加载并重启
```
systemctl daemon-reload
systemctl restart kubelet
```
4.前后对比图  
![微信截图_20220411111417.png](https://s2.loli.net/2022/04/11/axTFGp5kjNiIRyV.png)
