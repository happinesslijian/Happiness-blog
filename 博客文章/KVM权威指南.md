KVM权威指南
===
1.什么是虚拟化？
=========
**虚拟化，通过模拟计算机的硬件，来实现在同一台计算机上同时运行多个不同的操作系统的技术。**

2.为什么要用虚拟化？
=========
**kvm: 兼容较好,性能较好! 支持内存压缩技术**

**qemu:最早,最慢,兼容性最强,模拟所有硬件, x86,arm,power AIX**

**xen: 性能最好,兼容性最差,使用专门定制的内核,**

**vmware ESXI商业软件: 最贵,好用**

**virtual box: 开源**  

**没有虚拟化之前:**  
**计算机的硬件配置越来越高**

**512G 内存，4路 8核16线程 ，12\* PCI-E 1T的SSD**  
**ntp服务，安装多个mysql，安装多个tomcat，安装....**

**linux开源的，很多软件都有依赖包openssl nginx**

**充分利用资源，软件运行环境的隔离，只有虚拟化才行实现。**

**场景1：同一台物理机运行多个php版本 php5.3(openssl,gd) php5.5 php7.2**

**场景2：机房的迁移，解决了硬件和系统的依赖**

**场景3：openstack环境，软件发布方式**

**场景4：开发环境和测试环境，使用虚拟化  
只靠一台物理服务器，30台虚拟机**

**产品 -- 开发 -- 运维 -- 测试  
so结尾,linux 库文件**

**场景5：业务的快速部署  
从头安装系统，安装服务，配置  
克隆虚拟机，改ip，**

**虚拟化：提高了资源的利用率，各个服务的安全性隔离，解决了系统和硬件之间的依赖**

第一章 安装kvm虚拟机
============
1.Centos7.6版本
-------------
2.宿主机4G 处理器勾选 虚拟化Inter VT-x/EPT或AWD-V/RVI(V)
--------------------------------------------
3.kvm虚拟化管理软件的安装
---------------
```
#安装服务
yum install libvirt virt-install qemu-kvm -y
解释：
KVM：Kernel-based Virtual Machine  

libvirt  作用：虚拟机的管理软件,管理虚拟机的生命周期
libvirt: kvm,xen,qemu,lxc....

virt   virt-install virt-clone   作用：虚拟机的安装工具和克隆工具
qemu-kvm  qemu-img (qcow2,raw)作用：管理虚拟机的虚拟磁盘

#启动虚拟机管理服务
systemctl start libvirtd.service
systemctl status libvirtd.service
建议虚拟机内存不要低于1024M，否则安装系统特别慢！
virt-install --virt-type kvm --os-type=linux --os-variant rhel7 --name centos7 --memory 1024 --vcpus 1 --disk /opt/centos7.raw,format=raw,size=10 --cdrom /opt/CentOS-7-x86_64-DVD-17.iso --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole
解释：
--virt-type kvm    虚拟化的类型(qemu)
--os-type=linux    系统类型
--os-variant rhel7 系统版本
--name centos7     虚拟机的名字 
--memory 1024      虚拟机的内存
--vcpus 1          虚拟cpu的核数
--disk /opt/centos2.raw,format=raw,size=10
--cdrom /opt/CentOS-7-x86_64-DVD-1804.iso 
--network network=default   使用默认NAT的网络
--graphics vnc,listen=0.0.0.0 
--noautoconsole

raw：10G  不支持做快照，性能好
qcow2：   支持快照

#打开VNC客户端，安装系统

virsh start centos7     #启动虚拟机
```
第二章 KVM常用管理命令
=============
### 查看虚拟机
```
virsh list
virsh list --all
```
### 启动虚拟机
```
virsh start centos7
```
### 重启虚拟机
```
virsh reboot centos7
```
### 关闭虚拟机
```
virsh shutdown centos7
virsh destroy centos7
```
### 查看配置文件
```
virsh dumpxml centos7
```
导出配置文件
```
virsh dumpxml centos7 > centos7.xml
```
### 删除虚拟机
```
virsh destroy centos7
virsh undefine centos7
```
### 导入虚拟机
```
virsh define centos7.xml
```
### 虚拟机重命名
```
virsh domrename panghu shouhu
```
### 主机挂起
```
virsh suspend centos7
```
### 恢复主机
```
virsh resume centos7
```
### kvm虚拟机开机启动
```
virsh autostart centos7
ll /etc/libvirt/qemu/autostart/
```
小项目：
----
**把虚拟机磁盘迁移到/data目录并且启动**
#### 0.停止要迁移的虚拟机
```
virsh shutdown centos7
```
#### 1.创建数据目录并移动磁盘文件
```
mkdir /data 
mv /opt/centos7.raw /data 
```
#### 2.使用edit命令修改配置文件
```
virsh edit centos7
--------------------
 <source file='/data/centos7.raw'/>
--------------------
```
#### 3.启动虚拟机
```
virsh start centos7
virsh list 
```
第三章 KVM连接方式
===========
#### 1.VNC
```
virsh vncdisplay centos7
```
#### 2.SSH
#### 3.console显示
登录进需要开启console的虚拟机并添加参数
=======================
```
ssh 192.168.122.{i}  #变量随机数
grubby --update-kernel=ALL --args="console=ttyS0,115200n8"
grep "115200" /boot/grub2/grub.cfg 
reboot
virsh console centos7
#退出
ctrl + ]
```
第四章 KVM磁盘管理
===========
#### 1.虚拟机磁盘格式介绍
**raw：不支持做快照，性能好**  
**qcow2：支持快照，性能不如raw好**
#### 2.查看磁盘信息
```
qemu-img info centos7.raw 
```
#### 3.创建磁盘
```
qemu-img create -f qcow2 /data/centos7.qcow2 1G
```
#### 4.查看磁盘信息
```
qemu-img info centos7.qcow2
```
#### 5.调整磁盘容量: 只能加不能减
```
qemu-img resize /data/centos7.qcow2 1T
```
#### 6.磁盘格式转换
##### 1.将虚拟机关机
```
virsh destroy centos7
```
##### 2.转换磁盘格式
```
qemu-img convert -f raw -O qcow2 centos7.raw centos7.qcow2  
```
#### 3.编辑配置文件修改为qcow2格式
```
virsh edit centos7
------------------------------------------
      <driver name='qemu' type='qcow2'/>
      <source file='/opt/centos7.qcow2'/>
------------------------------------------
```
##### 4.重新启动
```
virsh start centos7
virsh console centos7
```
第五章 KVM快照管理
===========
#### 1.查看快照
```
virsh snapshot-list centos7
```
#### 2.创建快照
```
virsh snapshot-create-as centos7 snap1
virsh snapshot-list centos7
```
#### 3.恢复快照
```
virsh snapshot-revert centos7 snap1
```
#### 4.删除快照
```
virsh snapshot-delete centos7 snap1
```
第六章 KVM克隆虚拟机
============
### 1.完整克隆
```
virsh shutdown centos7
virt-clone --auto-clone -o centos7 -n centos7-backup
virsh list --all
virsh dumpxml web-blog-backup |grep "qcow2"
virsh snapshot-list centos7
```
### 2.链接克隆
##### 生成虚拟机磁盘文件
```
qemu-img create -f qcow2 -b centos7.qcow2 centos7-clone.qcow2 
```
#### 查看磁盘信息
```
qemu-img info centos7-clone.qcow2 
```
#### 生成虚拟机配置文件
```
virsh dumpxml centos7 > centos7-clone.xml
sed -i '/uuid/d' centos7-clone.xml
sed -i '/mac address/d' centos7-clone.xml
sed -i 's#centos7.qcow2#centos7-clone.qcow2#g' centos7-clone.xml
sed -i '/\<nam/s#centos7#centos7-clone#g' centos7-clone.xml
```
#### 导入配置文件
```
virsh define centos7-clone.xml 
virsh list --all 
```
#### 启动虚拟机
```
virsh start centos7-clone
```
第七章 KVM桥接网络
===========
#### 默认NAT模式
### 桥接模式
**为了方便测试，可以在VM虚拟机上打开DHCP功能**
### 1.创建桥接网卡和取消桥接网卡
```
virsh iface-bridge eth0 br0
virsh iface-unbridge br0
```
### 2.连接克隆新磁盘
```
cd /opt
qemu-img create -f qcow2 -b centos7.qcow2 bridge.qcow2
```
### 3.创建新虚拟机
```
virt-install --virt-type kvm --os-type=linux --os-variant rhel7 --name centos7-bridge --memory 1024 --vcpus 1 --disk /opt/bridge.qcow2 --boot hd --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole
```
### 4.登录虚拟机查看网卡信息
```
virsh console centos7-bridge
ip a
```
### 5.在其他主机ping测试
第八章 KVM虚拟机热添加磁盘
===============
### 1.热添加硬盘
#### 创建磁盘
```
qemu-img create -f qcow2 centos7-add.qcow2 10G
```
#### 临时生效添加
```
virsh attach-disk centos7 /opt/centos7-add.qcow2 vdb --subdriver qcow2
```
#### 虚拟机格式化并挂载
```
virsh console centos7
fdisk -l
mkfs.xfs /dev/vdb
mount  /dev/vdb  /mnt/
df -h
```
#### 永久生效添加
```
virsh attach-disk centos7 /opt/centos7-add.qcow2 vdb --subdriver qcow2
virsh attach-disk centos7 /opt/centos7-add.qcow2 vdb --subdriver qcow2 --config
```
### 2.剥离磁盘
#### 临时剥离
```
virsh detach-disk centos7 vdb
```
#### 永久剥离
```
virsh detach-disk centos7 vdb
virsh detach-disk centos7 vdb --config
```
### 3.调整磁盘大小
#### 调整磁盘大小
```
qemu-img info /opt/centos7-add.qcow2
qemu-img resize /opt/centos7-add.qcow2 +10G
```
#### 添加到虚拟机并查看
```
virsh attach-disk centos7 /opt/centos7-add.qcow2 vdb --subdriver qcow2
virsh console centos7
fdisk -l /dev/vdb
mount /dev/vdb /mnt/
df -h|tail -1 
```
#### 调整磁盘信息
```
xfs_growfs /dev/vdb
df -h|tail -1
```
第九章 KVM热添加网卡
============
### 临时添加
```
virsh attach-interface centos7 --type bridge --mac 52:54:00:b1:b5:8a --source br0 --model virtio detachinterface
```
#### 永久生效
```
virsh attach-interface centos7 --type bridge --mac 52:54:00:b1:b5:8a --source br0 --model virtio detachinterface --config 
```
### 临时剥离
```
virsh detach-interface centos7 bridge
```
#### 永久剥离
```
virsh detach-interface centos7 bridge
virsh detach-interface centos7 bridge --config
```
第十章 KVM热添加内存
============
### 创建虚拟机时直接添加最大内存参数
```
virt-install --virt-type kvm --os-type=linux --os-variant rhel7 --name centos7 --
memory 512,maxmemory=2048 --vcpus 1 --disk /opt/centos7.qcow2 --boot hd --network bridge=br0 --
graphics vnc,listen=0.0.0.0 --noautoconsole
```
### 如果创建虚拟机的时候没有设置最大内存限制，执行如下操作添加配置
```
virsh destroy centos7
virsh setmaxmem centos7 4096M
virsh start centos7 
virsh console centos7
free -h 
```
### 临时添加
```
virsh setmem centos7 2048M --live 
virsh console centos7
free -h 
```
### 永久增大内存
```
virsh setmem centos7 2048M --config
virsh console centos7
free -h 
```
第十一章 kvm虚拟机热与冷添加cpu
===================
KVM热添加cpu
---------
### 创建最大cpu核数
```
virt-install --virt-type kvm --os-type=linux --os-variant rhel7 --name centos7 --memory 512,maxmemory=2048 --vcpus 1,maxvcpus=10 --disk /data/centos7.qcow2 --boot hd --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole
```
### 热添加cpu核数
```
setvcpus centos7 4 --live
```
### 永久添加cpu核数
```
setvcpus centos7 4 --config
```
KVM冷添加cpu
---------
### 编辑配置文件
```
virsh edit centos7
------------------------------------------------
  <vcpu placement='static' current='2'>4</vcpu>
------------------------------------------------
```
添加cpu核数
=======
```
virsh setvcpus centos7 4 --live 
```
### 永久添加cpu核数
```
setvcpus centos7 4 --config
```
第十二章 esxi安装部署
=============
安装操作文档：[https://blog.51cto.com/10802692/2409826](https://links.jianshu.com/go?to=https%3A%2F%2Fblog.51cto.com%2F10802692%2F2409826)

kvm虚拟机迁移到esxi上
--------------
**直接使用qemu-img convert 转换为vmdk镜像是无法从ESXI中启动的.**
**首先使用qemu-img 转换镜像为vmdk.**
```
qemu-img convert -f qcow2 oldimage.qcow2 -O vmdk newimage.vmdk
```
将该镜像上传至Vmware存储.使用vmkfstools重制镜像
```
vmkfstools -i oldimage.vmdk newimage.vmdk -d thin
```
第十三章 kvm图形化管理工具部署
=================
```
1.初始化
rm -rf /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

2.安装python依赖
yum -y install git python-pip libvirt-python libxml2-python python-websockify supervisor gcc python-devel
python -m pip install --upgrade --force pip -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install setuptools==33.1.1 -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install numpy -i https://pypi.tuna.tsinghua.edu.cn/simple

3.安装python的Django环境
cd /opt/
git clone git://github.com/retspen/webvirtmgr.git
cd webvirtmgr
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
./manage.py syncdb
./manage.py collectstatic

4.安装Nginx
cat>/etc/yum.repos.d/nginx.repo<<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF
yum makecache fast
yum install nginx -y
yum clean all 

5.配置Nginx和代码
mkdir /code
mv /opt/webvirtmgr /code/
chown -R nginx:nginx /code
rm -rf /etc/nginx/conf.d/default.conf
cat >/etc/nginx/conf.d/webvirtmgr.conf<<EOF
server {
    listen 80 default_server;

    server_name localhost;
    access_log /var/log/nginx/webvirtmgr_access_log; 

    location /static/ {
        root /code/webvirtmgr;        
        expires max;
    }
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-for \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 600;
        proxy_read_timeout 600;
        proxy_send_timeout 600;
        client_max_body_size 1024M; 
    }
}
EOF
nginx -t
nginx
netstat -lntup|grep 80

6.配置Supervisor
cat >/etc/supervisord.d/webvirtmgr.ini<<EOF
[program:webvirtmgr]
command=/usr/bin/python /code/webvirtmgr/manage.py run_gunicorn -c /code/webvirtmgr/conf/gunicorn.conf.py
directory=/code/webvirtmgr
autostart=true
autorestart=true
logfile=/var/log/supervisor/webvirtmgr.log
log_stderr=true
user=nginx

[program:webvirtmgr-console]
command=/usr/bin/python /code/webvirtmgr/console/webvirtmgr-console
directory=/code/webvirtmgr
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/webvirtmgr-console.log
redirect_stderr=true
user=nginx

[program:nginx]
command=nginx -g 'daemon off;'
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/nginx.log
redirect_stderr=true
EOF
sed -i "s#nodaemon=false#nodaemon=true#g" /etc/supervisord.conf
supervisord -c /etc/supervisord.conf
重新打开一个终端
supervisorctl status

7.创建用户
mkdir /var/cache/nginx/.ssh/ -p
chown -R nginx:nginx /var/cache/nginx/
su - nginx -s /bin/bash
ssh-keygen
touch ~/.ssh/config && echo -e "StrictHostKeyChecking=no\nUserKnownHostsFile=/dev/null" >> ~/.ssh/config
chmod 0600 ~/.ssh/config
ssh-copy-id root@10.0.0.113（需要管理的kvm机器的ip地址）
```
详情见：\
https://github.com/happinesslijian/Happiness-blog/blob/master/%E5%8D%9A%E5%AE%A2%E6%96%87%E7%AB%A0/%E5%AE%89%E8%A3%85webvirtmgr.md \
https://github.com/happinesslijian/Happiness-blog/blob/master/%E5%8D%9A%E5%AE%A2%E6%96%87%E7%AB%A0/webvirtmgr%E6%B7%BB%E5%8A%A0%E4%B8%BB%E6%9C%BA.md

![](https://upload-images.jianshu.io/upload_images/19559641-328fdecf8c6e96ff.png)
![](https://upload-images.jianshu.io/upload_images/19559641-08b8a4513c21c102.png)
![](https://upload-images.jianshu.io/upload_images/19559641-3955549fb1148884.png)
![](https://upload-images.jianshu.io/upload_images/19559641-ef89976c03c9c914.png)
