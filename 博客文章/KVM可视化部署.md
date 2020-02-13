# KVM虚拟化—可视化
详情请看：
https://www.jianshu.com/p/b3a2638c9bcd
## 卸载：
  - 删除可视化操作
```
rm -rf /etc/nginx/
rm -rf /etc/wok/
yum remove nginx-mod* -y
netstat -ntlp（查看已经没有80端口）
![](https://upload-images.jianshu.io/upload_images/16739463-391a5f72cb0943d2.png)
```
## 安装：
- 下载文件：
```
https://github.com/kimchi-project/kimchi/releases/tag/2.4.0
#我这里使用的是contos
![](https://upload-images.jianshu.io/upload_images/16739463-af864c5eeebfcc2f.png)
yum -y installwok-2.4.0-0.el7.centos.noarch.rpm ginger-base-2.3.0-0.el7.centos.noarch.rpmkimchi-2.4.0-0.el7.centos.noarch.rpm
```
- 重新加载服务
```
systemctl daemon-reload
systemctl daemon-reload
systemctl restart nginx
#查看是否已经开启80端口
netstat -ntlp
![](https://upload-images.jianshu.io/upload_images/16739463-bfabffa9259c60de.png)
```
## 浏览器访问
192.168.100.202:8001
输入centos系统的用户名密码
![](https://upload-images.jianshu.io/upload_images/16739463-87c4f70d537aa507.png)
登录日志
![](https://upload-images.jianshu.io/upload_images/16739463-941b6d759e796e38.png)
这时候是没有Virtualization选项的，
查看日志
cat /var/log/wok/wok-error.log
日志说明存储资源池冲突
![](https://upload-images.jianshu.io/upload_images/16739463-af27c372b8196478.png)
需要做如下操作
查看存储池如下：
virsh pool-list --all
![](https://upload-images.jianshu.io/upload_images/16739463-37eee89ccea0d2a7.png)
编辑kimchi配置文件
vim /etc/kimchi/template.conf
改成红框内的字样（要和默认资源池对应上）
![](https://upload-images.jianshu.io/upload_images/16739463-114140f24641d147.png)
重启wokd
systemctl restart wokd
重新刷新WEB界面
![](https://upload-images.jianshu.io/upload_images/16739463-602279f6eeb2dc2a.png)
查看最新版本的可视化
https://github.com/kimchi-project/kimchi/releases/
关于wok、kimchi、ginger-base相关理论知识查看
https://www.jianshu.com/p/dade959b9bf0
