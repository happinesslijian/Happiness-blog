# Docker最简单管理方法之Portainer

![](https://static01.imgkr.com/temp/cb1ef82ac0b94071821c9a9359a0a7d7.jpg)
## Portainer 简介
`Portainer`：是用于 Docker `轻量级`，`跨平台`，`开源管理` 的UI工具。Portainer 提供了Docker详细概述，并允许您通过基于Web 简单仪表盘管理容器、镜像、网络和卷。

## Portainer 安装
```bash
# 挂载 docker.sock 到Portainer容器中
$ docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer
```

## 使用方法
- 访问 http://IP_Address:9000/ UI界面，设置管理员账号，如果容器启动后，`5分钟之内`没有设置管理员密码就会自动停止容器

![](https://static01.imgkr.com/temp/266d5f0292e74c2db33129dabb57d587.png)


- 选择连接本地容器，容器启动时需要把 `/var/run/docker.sock` 挂载到容器中

![](https://static01.imgkr.com/temp/b7c9c13dd54d4cba824b70422d336603.png)


- Portainer 概览

![](https://static01.imgkr.com/temp/cbfce37d32c241eebc7d5962d0b37537.png)
