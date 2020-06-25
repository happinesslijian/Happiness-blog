# mysql启动时自动执行初始建表脚本

![](https://imgkr.cn-bj.ufileos.com/083f4e37-b902-4c7b-93cf-e2c922944837.jpg)

默认情况下，mysql镜像创建的docker容器启动时只是一个空的数据库实例，为了简化docker部署,我们需要在docker创建mysql容器的时，数据库和表已经自动建好，初始化数据也已自动录入，也就是说容器启动后数据库就可用了。这就需要容器启动时能自动执行sql脚本。
在mysql官方镜像中提供了容器启动时自动执行/docker-entrypoint-initdb.d
也就是说只要把你自己的初始化脚本放到`/docker-entrypoint-initdb.d/`文件夹下就齐活了
```
# Dockerfile

FROM mysql:5.7.28

COPY ./db_aicube.sql /docker-entrypoint-initdb.d
```
docker启动命令如下
```
docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -e MYSQL_DATABASE=db_aicube -d mysql:5.7.28
```