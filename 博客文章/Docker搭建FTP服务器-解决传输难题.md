# Docker搭建FTP服务器-解决传输难题

### 如果没有安装docker请执行如下：
```
# 官方源
curl -fsSL https://get.docker.com | bash
# 阿里云源
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
# 开机自启
systemctl enable docker 
# 启动
systemctl start docker
```

### 运行docker
```
docker run -d -p 21:21 -p 20:20 -p 21100-21110:21100-21110 -v /root/ftp/:/home/vsftpd -e FTP_USER=admin -e FTP_PASS=passwd -e PASV_ADDRESS=10.121.140.209 -e PASV_MIN_PORT=21100 -e PASV_MAX_PORT=21110 --name ftp --restart always fauria/vsftpd
```

### 用户验证配置
```
# 登录容器内
docker exec -it ftp bash

# 如果需要创建新用户，需要将用户和密码接入到以下文件内，默认里面包含了Docker启动容器时候创建的用户名和密码
[root@25b1fd56c803 /]# cat /etc/vsftpd/virtual_users.txt
admin
passwd

#假如我们添加了user用户，我们需要建立对应用户的文件夹
mkdir /home/vsftpd/user

#把登录的验证信息写入数据库 
/usr/bin/db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db
```
### 重启容器
```
docker restart ftp
```
然后即可在window上找一个FTP软件远程连接即可