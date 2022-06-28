## 在Dockerfile中获取主机IP

#### 问题描述：  
> 我在dockerfile中有一行echo "DB_HOST=192.168.0.216" >> /var/www/html/tci-api/.env  
我想让IP动态化。我如何获得主机IP？

#### 提示: 最好不要在构建时设置Docker主机IP，否则图像将与其构建的主机绑定，并且在其他任何地方都无法工作。

#### 方式一
通过本地传参给到容器本机IP地址  
`ENTRYPOINT`可用于根据环境变量进行配置设置，然后将所有命令传递给容器：
```
#!/bin/bash
if [ -n "$IP_ADDRESS" ]; then
	  echo "DB_HOST=$IP_ADDRESS" >> /var/www/html/tci-api/.env
else
	  echo "No environment variable IP_ADDRESS set for xdebug"
fi
exec "$@"
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
```
Dockerfile如下：
```
FROM hongwenjun/nginx-php:latest
ARG IP_ADDRESS
ADD tci-api  /var/www/html/tci-api
ADD nginx_proxy.conf  /etc/nginx/sites-enabled/default
ADD scripts.sh /
RUN chmod 777 /scripts.sh
EXPOSE 80
ENTRYPOINT [ "bash", "-c", "/scripts.sh" ]
```
运行命令：
```
docker run -dit --name test -e IP_ADDRESS=$(ip a | grep ens3 | grep inet | awk '{print $2}' | awk -F'/' '{print $1}')  test/123
```
#### 方式二
通过docker网桥和物理节点进行通信  
`ENTRYPOINT`可用于根据环境变量进行配置设置，然后将所有命令传递给容器：
```
#!/bin/bash
## 拿到docker网桥IP
ip=`route -n | grep ^0.0.0.0|tr -s ' '|cut -d ' ' -f2`
## 修改替换对应的配置文件
sed -i "/^DB_HOST*/c\DB_HOST=${ip}" /var/www/html/tci-api/.env
rm -rf /var/www/html/tci-api/bootstrap/cache/config.php
php /var/www/html/tci-api/artisan config:cache
php /var/www/html/tci-api/artisan config:clear
# Start supervisord and services
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
```
Dockerfile如下：
```
FROM hongwenjun/nginx-php:latest
ADD tci-api  /var/www/html/tci-api
ADD nginx_proxy.conf  /etc/nginx/sites-enabled/default
ADD start.sh /
EXPOSE 80
ENTRYPOINT [ "bash", "-c", "/start.sh" ]
```





