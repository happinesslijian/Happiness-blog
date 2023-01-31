#!/bin/bash
mkdir -p /etc/promtail/
yum -y install unzip 

wget -c https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip
if [ $? -ne 0 ]; then
    while true
    do
        wget -c https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip
        if [ $? -eq 0 ]; then
            break
        fi
    done
else
    unzip promtail-linux-amd64.zip
    mv promtail-linux-amd64 /usr/local/bin/promtail
fi

echo -n "请输入Loki服务端IP:"
read IP

echo -n $HOSTNAME
echo -e '\033[1;31m 写入配置文件到/etc/promtail/promtail-local-config.yaml \033[0m'
cat << EOF > /etc/promtail/promtail-local-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://${IP}:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: system
      __path__: /var/log/*log
      
# 如下写法会收集该目录下所有子目录中所有的(类似filebeat 穿透子目录查找日志文件,并索引)递归查询

# 参考链接 https://github.com/bmatcuk/doublestar#patterns

- job_name: ${HOSTNAME}-logs
  static_configs:
  - targets:
      - localhost
    labels:
      job: ${HOSTNAME}-logs
      __path__: /var/log/{,*/}{*[._]log,{mail,news}.{err,info,warn}}

# 递归查询可以查询到子目录中的日志,但是/var/log/目录下就查询不到了,比如：messages查询不到,所以要手动指定,如下：

- job_name: ${HOSTNAME}-messages-logs
  static_configs:
  - targets:
      - localhost
    labels:
      job: ${HOSTNAME}-messages-logs
      __path__: /var/log/messages

# 而 /var/log/**/*.log 用于递归匹配文件与目录(包含如上两个)

- job_name: ${HOSTNAME}-logs
  static_configs:
  - targets:
      - localhost
    labels:
      job: ${HOSTNAME}-logs
      __path__: /var/log/**/*.log

EOF
echo -e '\033[1;31m 执行完毕,请查看Loki  job选项 \033[0m'

cat > /etc/systemd/system/promtail.service <<EOF

[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/promtail --config.file /etc/promtail/promtail-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl restart promtail && systemctl status promtail && systemctl enable promtail
