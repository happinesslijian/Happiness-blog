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

### 编写了一个脚本
### Change_Pod_quantity.sh
```
#!/bin/bash
file=/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
newExecStart='ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS $KUBELET_NODE_MAX_PODS'
ls -al $file
if [ "$?" = 0 ]; then
read -r -p "输入要扩展的数量: " input0
        expr $input0 + 0 &> /dev/null
        if [ $? != 0 ]; then
                echo "请输入数字!"
        elif [ $input0 -gt 110 ] && [ $input0 -le 200 ]; then
                #可以直接删除第11行,但是这样不太友好,所以这里使用了注释以ExecStart开头的行 #&的意思是匹配任意字符
                #sed -i '11d' $file
                sed -i 's/^ExecStart=\/usr\/bin\/kubelet/#&/' $file
                echo Environment="KUBELET_NODE_MAX_PODS=--max-pods=$input0" >> $file
                echo $newExecStart >> $file
                systemctl daemon-reload
                systemctl restart kubelet
        else
                echo "输入的值须大于110,且小于等于200"
        fi
else
        echo "没有这个文件或目录"
fi
```
