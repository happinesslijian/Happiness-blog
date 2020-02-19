## cockpit的安装和基本使用

### 安装cockpit(cockpit-server)
```
yum -y install cockpit cockpit-dashboard cockpit-storaged cockpit-packagekit
# 启动cockpit并设为开启自启动
systemctl enable --now cockpit.socket && systemctl list-unit-files | grep cockpit && systemctl start cockpit
```
- 可选组件列表

| 功能名称 | 包名称 | 使用说明 |
|:--:|:--:|:--:|
| Composer | Building custom OS | images |
| Dashboard | cockpit-dashboard | Managing multiple servers in one UI |
| Machines | cockpit-machines | Managing libvirt virtual machines |
| PackageKit | cockpit-packagekit | Software updates and application installation (usually installed by default) |
| PCP | cockpit-pcp | Persistent and more fine-grained performance data (installed on demand from the UI) |
| podman | cockpit-podman | Managing podman containers (available from RHEL 8.1) |
| Session Recording | cockpit-session-recording| Recording and managing user sessions |

- 添加其他主机
  - 需要在被添加主机(cockpit-node)上也安装cockpit(安装完即无须启动)
    ```
    yum -y install cockpit
    ```
### 浏览器验证
![](https://imgkr.cn-bj.ufileos.com/574f887f-cf97-45ab-9372-20d7313aa6e9.png)
### 添加其他主机
![](https://imgkr.cn-bj.ufileos.com/b98d1afd-dc64-490e-be52-a2216325e66c.png)
### 参考文档：
https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/managing_systems_using_the_rhel_7_web_console/index

https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_systems_using_the_rhel_8_web_console/index

https://www.kclouder.cn/howtocockpit/

https://slowread.net/blog/cockpit-%E4%B8%80%E4%B8%AA%E5%9F%BA%E4%BA%8Eweb%E7%9A%84%E4%BA%A4%E4%BA%92%E5%BC%8F%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7/

### 总结
cockpit是一个简单可用的监控工具,你可以添加多个主机进行监控,上限是 **`20台`** 也可以使用cockpit来管理虚拟机/容器. 也可以安装其他组件开启更多功能.
> 注意：cockpit没有告警功能,不适用于生产环境.