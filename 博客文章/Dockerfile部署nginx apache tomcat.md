### nginx
```
#安装nginx并用CMD设置默认启动命令
#默认初始镜像为centos:7
FROM centos:7
RUN yum install -y epel-release && yum install -y nginx
CMD ["nginx","-g","daemon off;"]
```
### apache
```
#安装http并用CMD设置默认启动命令
#默认初始镜像为centos:7
FROM centos:7
RUN yum install -y httpd
CMD ["httpd","-D","FOREGROUND"]
```
### tomcat
```
#安装jdk tomcat并启动
#默认初始镜像为centos:7
FROM centos:7
ADD ./apache-tomcat-9.0.12.tar.gz /root
ADD ./jdk-8u181-linux-x64.tar.gz /root
ENV JAVA_HOME /root/jdk1.8.0_181
ENV PATH $JAVA_HOME/bin:$PATH
RUN echo JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom" >> /root/apache-tomcat-9.0.12/bin/catalina.sh
ENTRYPOINT /root/apache-tomcat-9.0.12/bin/startup.sh && tail -F /root/apache-tomcat-9.0.12/logs/catalina.out
```
### jdk
```
#安装jdk
#默认初始镜像为centos:7
FROM centos:7
ADD ./jdk-8u181-linux-x64.tar.gz /root
ENV JAVA_HOME /root/jdk1.8.0_181
ENV PATH $JAVA_HOME/bin:$PATH
```
### Redis
```
#安装http并用CMD设置默认启动命令
#默认初始镜像为centos:7
FROM centos:7
RUN yum -y update &&  yum -y install epel-release && yum -y install redis && yum -y install net-tools
EXPOSE 6379
ENTRYPOINT [ "/usr/bin/redis-server" ]
CMD []
```
