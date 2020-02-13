1.创建SSH私钥和ssh配置选项(在安装了WebVirtMgr的系统上):
```
$ sudo su - nginx -s /bin/bash
$ ssh-keygen
Enter file in which to save the key (path-to-id-rsa-in-nginx-home): 只需点击此处输入!!
$ touch ~/.ssh/config && echo -e "StrictHostKeyChecking=no\nUserKnownHostsFile=/dev/null" >> ~/.ssh/config
$ chmod 0600 ~/.ssh/config
```
2.在webvirtmgr主机上，然后将公钥复制到qemu-kvm / libvirt主机服务器：
```
$ sudo su - nginx -s /bin/bash
# 注意:以下的root用户是qemu-kvm的管理用户(你用哪个用户创建并管理的KVM,这里就写哪个用户)
$ ssh-copy-id root@qemu-kvm-libvirt-host 或者 ssh-copy-id root@IP
或者，如果您更改了默认的SSH端口，请使用：
$ ssh-copy-id -p YOUR_SSH_PORT root@qemu-kvm-libvirt-host 或者 ssh-copy-id root@IP
现在，您可以通过输入以下内容来测试连接：
$ ssh root@qemu-kvm-libvirt-host 或者 ssh-copy-id
对于非标准SSH端口，请使用：
$ ssh -p YOUR_SSH_PORT root@qemu-kvm-libvirt-host 或者 ssh-copy-id root@IP
您应该在不输入密码的情况下进行连接。
```
3.打开webvirtmgr-dashboard进行添加额外的qemu-kvm进行统一管理 如下图:
![微信截图_20200212115638.png](https://i.loli.net/2020/02/12/O5nFrPlmsRAw678.png)
4.推荐管理架构 如下图
![推荐架构图.png](https://i.loli.net/2020/02/12/VdLqF4QSkHKsicR.png)
