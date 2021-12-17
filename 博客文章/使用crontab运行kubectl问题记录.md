### 使用crontab定时执行kubectl

问题:自己写了个kubectl命令删除失败pods的脚本，然后crontab自动执行总是失败
分析：
1. 找到kubectl的完整路径
```
which kubectl 
/usr/local/bin/kubectl
#或者
whereis kubectl 
/usr/local/bin/kubectl
```
2. 查看crontab的环境变量
```
cat /etc/crontab

SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
```
3. 查看环境变量
```
echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
能发现cron环境变量少了/usr/local/bin /usr/local/sbin/和/root/bin
```
4. 解决
```
#在脚本里加入一行
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
```
例子：
```
#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
kubectl delete secret kubevirt-virt-api-certs kubevirt-virt-handler-certs -n kubevirt
sleep 5
kubectl delete pod -n kubevirt `kubectl get --no-headers=true pod -n kubevirt | awk {'print $1'}`
```
