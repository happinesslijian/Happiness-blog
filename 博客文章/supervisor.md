# supervisor

1. 系统平台
```
cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core) 
```
2. Python版本
```
python -V
Python 2.7.5
# python版本需大于2.6
```
3. 安装 Supervisor
```
yum install -y supervisor
systemctl start supervisord
systemctl enable supervisord
```
4. 编写需要被Supervisor管理的进程
```
vim /etc/supervisord.d/fs-server.conf

[program:fs-server]                         #程序唯一名称
command=python3 /mnt/fs-server/main.py      #运行程序的命令
directory=/mnt/fs-server/                   #程序路径
user=root                                   #用哪个用户启动进程，默认是root
autorestart=true                            #程序退出后自动重启,可选值：[unexpected,true,false]，默认为unexpected，表示进程意外杀死后才重启；意思为如果不是supervisord来关闭的该进程则认为不正当关闭，supervisord会再次把该进程给启动起来，只能使用该supervisorctl来进行关闭、启动、重启操作
redirect_stderr=true                        #把stderr重定向到stdout标准输出，默认false
stdout_logfile=/mnt/fs-server.log           #标准日志输出位置，如果输出位置不存在则会启动失败
loglevel=info                               #日志级别
```
5. 编写需要被Supervisor管理的进程
```
vim /etc/supervisord.d/kube-server.conf

[program:kube-server]                         #程序唯一名称
command=python3 /mnt/kube-server/main.py      #运行程序的命令
directory=/mnt/kube-server/                   #程序路径
user=root                                   #用哪个用户启动进程，默认是root
autorestart=true                            #程序退出后自动重启,可选值：[unexpected,true,false]，默认为unexpected，表示进程意外杀死后才重启；意思为如果不是supervisord来关闭的该进程则认为不正当关闭，supervisord会再次把该进程给启动起来，只能使用该supervisorctl来进行关闭、启动、重启操作
redirect_stderr=true                        #把stderr重定向到stdout标准输出，默认false
stdout_logfile=/mnt/kube-server.log           #标准日志输出位置，如果输出位置不存在则会启动失败
loglevel=info                               #日志级别
```
6. 编写需要被Supervisor管理的进程
```
cat << EOF > /etc/supervisord.d/redis.conf
[program:redis]
command=/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis6001.conf
directory=/usr/local/redis
user=root
autorestart=true
redirect_stderr=true
stdout_logfile=/usr/local/redis/logs/redis6001.log
loglevel=info
EOF
```

**注意：**/etc/supervisord.d/目录下的所有`.conf`都会被作为被Supervisor管理的进程。(也有可能是`.ini`，可以通过`cat /etc/supervisord.conf | grep supervisord.d`或者`cat /var/log/supervisor/supervisord.log`查看)

7. 程序管理
```
supervisorctl status kube-server                              #kube-server状态
supervisorctl stop kube-server                                #停止kube-server
supervisorctl start kube-server                               #启动kube-server
supervisorctl restart kube-server                             #重启kube-server
supervisorctl reoload kube-server                             #重载kube-server
```
8. web访问
```
sed -i '10i[inet_http_server]' /etc/supervisord.conf 
sed -i '11iport=*:9001' /etc/supervisord.conf
sed -i '12iusername=user' /etc/supervisord.conf
sed -i '13ipassword=123' /etc/supervisord.conf

systemctl restart supervisord
curl -u user 192.168.0.190:9001
```
### 参考文档：  
https://zhuanlan.zhihu.com/p/147305277  
https://www.douban.com/note/657000902/