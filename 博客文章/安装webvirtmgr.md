# 须知：kvm 的 web 管理界面是由 webvirtmgr 程序提供的 我这里是在安装完qemu-kvm后安装的webvirtmgr
1. 安装依赖包
```
yum -y install git python-pip libvirt-python libxml2-python python-websockify supervisor nginx python-devel
```
2. 升级pip
```
pip install --upgrade pip
```
3. 从github上下载webvirtmgr代码
```
cd /usr/local/src/
git clone git://github.com/retspen/webvirtmgr.git
```
4. 安装webvirtmgr
```
cd webvirtmgr/
pip install -r requirements.txt
```
5. 检查sqlite3是否安装
```
python
import sqlite3
exit()
```
6. 初始化帐号信息
```
python manage.py syncdb
	You just installed Django's auth system, which means you don't have any superusers defined.
	Would you like to create one now? (yes/no): yes     //问你是否创建超级管理员帐号
	Username (leave blank to use 'root'):   //指定超级管理员帐号用户名，默认留空为root
	Email address: bebejo@126.com     //设置超级管理员邮箱
	Password:passwd       //设置超级管理员密码
	Password (again):passwd       //再次输入超级管理员密码
	Superuser created successfully.
	Installing custom SQL ...
	Installing indexes ...
	Installed 6 object(s) from 1 fixture(s)
```
7. 拷贝web网页至指定目录
```
mkdir /var/www
cp -r /usr/local/src/webvirtmgr/ /var/www/
chown -R nginx.nginx /var/www/webvirtmgr/
```
8. 生成密钥(全部默认 一路回车即可)
`ssh-keygen -t rsa`
9. 由于这里webvirtmgr和kvm服务部署在同一台机器，所以这里本地信任。如果kvm部署在其他机器，那么这个是它的ip（有待验证）
`ssh-copy-id`
10. 端口转发（有待验证）
```
ssh 192.168.100.202 -L localhost:8000:localhost:8000 -L localhost:6080:localhost:6080
ss -antl 
```
11. 配置nginx(我这里把默认的nginx.conf里面的所有配置都注释掉了,有待测试)
```
vim /etc/nginx/nginx.conf
```
12. 配置webvirtmgr.conf
```
vim /etc/nginx/conf.d/webvirtmgr.conf 

server {
listen 80 default_server;

server_name kvm.dashboard.com; #自定义域名
#access_log /var/log/nginx/webvirtmgr_access_log;

location /static/ {
    root /var/www/webvirtmgr/webvirtmgr;
    expires max;
}

location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-for $proxy_add_x_forwarded_for;
        proxy_set_header Host $host:$server_port;
        proxy_set_header X-Forwarded-Proto $remote_addr;
        proxy_connect_timeout 600;
        proxy_read_timeout 600;
        proxy_send_timeout 600;
        client_max_body_size 1024M;
  }
}
```
13. 确保bind绑定的是本机的8000端口
```
vim /var/www/webvirtmgr/conf/gunicorn.conf.py

bind = '127.0.0.1:8000'
backlog = 2048
```
14. 重启nginx
```
systemctl start nginx 
ss -antl
```
15. 设置supervisor 在文件最后面追加如下内容
```
vim /etc/supervisord.conf

[program:webvirtmgr]
command=/usr/bin/python2 /var/www/webvirtmgr/manage.py run_gunicorn -c /var/www/webvirtmgr/conf/gunicorn.conf.py
directory=/var/www/webvirtmgr
autostart=true
autorestart=true
logfile=/var/log/supervisor/webvirtmgr.log
log_stderr=true
user=nginx

[program:webvirtmgr-console]
command=/usr/bin/python2 /var/www/webvirtmgr/console/webvirtmgr-console
directory=/var/www/webvirtmgr
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/webvirtmgr-console.log
redirect_stderr=true
user=nginx
```
16. 启动supervisor并设置开机自动启动
```
systemctl start supervisord
systemctl enable supervisord
ss -antl 
```
17. 配置nginx用户
```
su - nginx -s /bin/bash
ssh-keygen -t rsa
touch ~/.ssh/config && echo -e "StrictHostKeyChecking=no\nUserKnownHostsFile=/dev/null" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
ssh-copy-id root@192.168.100.202
exit
---
vim /etc/polkit-1/localauthority/50-local.d/50-libvirt-remote-access.pkla
#添加下面内容
[Remote libvirt SSH access]
Identity=unix-user:root
Action=org.libvirt.unix.manage
ResultAny=yes
ResultInactive=yes
ResultActive=yes
---
chown -R root.root /etc/polkit-1/localauthority/50-local.d/50-libvirt-remote-access.pkla
systemctl restart nginx
systemctl restart libvirtd
```
# 验证 
浏览器输入http://IP或者http://自定义域名
我这里使用的是自定义域名
![16739463-842b989e4834dd99.png](https://i.loli.net/2020/02/12/dbWpjT5EJfOotHB.png)
**`用户名是：root`**
**`密码是执行python manage syncdb时设置的超级管理员密码`**
![16739463-e0be7bdb6ed17fcd.png](https://i.loli.net/2020/02/12/ByZs4f9ctNbCOUi.png)
**到这里基本就已经完成了，剩下的操作多实践几次就明白是怎么回事了**
# 说明：
如果你是安装完qemu-kvm之后安装的webvirtmgr那么你现在正常可以看到你所有的虚拟机了。**`我这里是先安装qemu-kvm后再安装webvirtmgr的！`**
我这里没有使用noVNC
如果有人知道`Failed to connect to server (code: 1000, reason: Target closed)`问题咋处理，请留言
# 问题说明：
- 问题1 
```
第一次通过web访问kvm时可能会一直访问不了，一直转圈，而命令行界面一直报错(too many open files)
	永久生效方法：
		修改/etc/security/limits.conf，在文件底部添加：
		* soft nofile 655360
		* hard nofile 655360
		星号代表全局， soft为软件，hard为硬件，nofile为这里指可打开文件数。
	 
	另外，要使limits.conf文件配置生效，必须要确保 pam_limits.so 文件被加入到启动文件中。
	查看 /etc/pam.d/login 文件中有：
	session required /lib/security/pam_limits.so
```
- 关于克隆
克隆虚拟机的时候如下 metadata选项不要勾选，会造成资源浪费 \
![16739463-28000fa54287e858.png](https://i.loli.net/2020/02/12/FgckBhvwqxymUPO.png)
- 关于创建虚拟机
创建虚拟机的时候如下metadata选项不要勾选，会造成资源浪费 \
![16739463-854c053b4233829c.png](https://i.loli.net/2020/02/12/3H1G8PINuM5CsX4.png)


