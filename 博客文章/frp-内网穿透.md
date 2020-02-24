### 准备工作：
1. 1台具有固定公网IP的服务器(我选择的是阿里云的服务器)
2. 至少1台内网机器(看你实际需要穿透的数量)

### frps
1. 在公网机器上下载frp软件,地址https://github.com/fatedier/frp/releases 并且解压到任意目录(我这里解压到`/srv/`下面)
2. 修改配置,我的配置主要如下:
```
# vim frps.ini

[common]
bind_port = 7000
vhost_http_port = 8080
vhost_http_port = 80
vhost_https_port = 443
bind_udp_port = 7001
admin_port = 7400
admin_user = admin
admin_pwd = admin
max_pool_count = 5
dashboard_port = 7500
dashboard_pwd = admin
max_pool_count = 100
token = 123456
```
3. 启动`frps`
```
#到/srv/下面执行
nohup ./frps -c ./frps.ini &
```
4. 监控脚本(优化方面,防止意外原因导致frps进程掉线)
```
# vim autostatus.sh
# chmod +x autostatus.sh

#!/bin/bash
frps=`ps -ef | grep frps | wc -l`
if [ "${frps}" -eq "1" ];then
        cd /srv/frps && nohup ./frps -c ./frps.ini &
fi
```
### frpc
1. 在内网机器上下载frp软件,地址https://github.com/fatedier/frp/releases 并且解压到任意目录(我这里解压到`/srv/`下面)
2. 修改配置,我的配置主要如下：
```
# vim frpc.ini

[common]
server_addr = aliyun ip 
server_port = 7000
token = 123456
pool_count = 100
login_fail_exit = false
use_compression = true
use_encryption = true

[k8s-master]
type = tcp
local_ip = 192.168.0.150
local_port = 22
remote_port = 1500
custom_domains = k8s-master.cn
use_compression = true
use_encryption = true

[物理机-远程桌面]
type = tcp
local_ip = 192.168.0.100
local_port = 3389
remote_port = 1000
custom_domains = acer.cn
use_compression = true
use_encryption = true

[nextcloud]
type = http
local_ip = 192.168.0.151
local_port = 30093
custom_domains = nextcloud.k8s.fit
use_compression = true
use_encryption = true

[blog]
type = http
local_port = 8080
custom_domains = blog.k8s.fit
use_compression = true
use_encryption = true
```
3. 连接frps
```
./frpc -c ./frpc.ini > /tmp/frpc.log 2>&1 &
```
4. 监控脚本(优化方面,防止意外原因导致frpc进程掉线)
```
# vim autostatus.sh
# chmod +x autostatus.sh

#!/bin/bash
frpc=`ps -ef | grep frpc | wc -l`
if [ "${frpc}" -eq "1" ];then
        cd /srv/frpc && ./frpc -c ./frpc.ini > /tmp/frpc.log 2>&1 &
fi
```
### 总结
有上面简单几条配置即可完成内网穿透,没有数量的限制,想怎么穿透就怎么穿透！
> 注意：如果穿透http协议或者https协议一定要提前做好域名的备案工作,否则80端口无法正常通信！

### 参考配置链接:
https://github.com/fatedier/frp/blob/master/README_zh.md

https://www.zeekling.cn/articles/2019/08/11/1565501357107.html
