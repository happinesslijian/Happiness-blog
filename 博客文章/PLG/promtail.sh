#!/bin/bash
mkdir -p /etc/promtail/
yum -y install unzip 

wget https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip
if [ $? -ne 0 ]; then
    while true
    do
        wget https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip
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
      job: varlogs
      __path__: /var/log/*log
EOF
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