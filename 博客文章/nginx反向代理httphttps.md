# 记录一下nginx代理80、代理443端口的说明
|端口|协议|
|:--:|:--:|
|80|http|
|443|https
- 首先要安装nginx，这里采用yum安装方式 
`yum -y install nginx`
- 安装完成后编辑其配置文件
`vim /etc/nginx/nginx.conf`
## 配置代理80端口
```
    server {
        listen       80;
        server_name  www.prometheus.test.com; #自定义域名
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
            proxy_pass http://192.168.100.158:9090; #填写对应主机IP
        }
    }
```
## 配置代理443端口
`因https方式需要涉及到证书，我这里使用openssl自创建证书`
```
openssl genrsa -out tls.key 2048
openssl req -new -x509 -days 365 -key tls.key -out tls.crt -subj /C=CN/ST=Beijingshi/L=Beijing/O=devops/CN=cn
```
```
    server {
        listen       80;
        listen	     443 ssl;
        ssl_certificate /data/tls.crt; #找到证书所在对应目录
        ssl_certificate_key /data/tls.key; #找到key所在对应目录
        server_name  www.grafana.test.com; #自定义域名
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
            proxy_pass http://192.168.100.158:3000; #填写对应主机IP
        }
    }
```
## http自动跳转https
```
    server {
        listen       80;
        listen       443 ssl;
        ssl_certificate /data/tls.crt; #找到证书所在对应目录
        ssl_certificate_key /data/tls.key; #找到key所在对应目录
        server_name  www.prometheus.test.com; #自定义域名
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
        # http自动跳转https
        if ($server_port = 80 ) {
                return 301 https://$host$request_uri;
        }

        location / {
            proxy_pass http://192.168.100.158:9090; #填写对应主机IP
        }
        # http自动跳转https
        error_page 497  https://$host$request_uri;
    }
```
最后来进行测试
`nginx -t`
返回的信息如下即成功
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```
重启nginx服务即可
`systemctl restart nginx`
