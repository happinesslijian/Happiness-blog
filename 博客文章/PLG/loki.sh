#!/bin/bash
mkdir -p /etc/loki/
yum -y install unzip 

wget https://github.com/grafana/loki/releases/download/v1.5.0/loki-linux-amd64.zip
if [ $? -ne 0 ]; then
    while true
    do
        wget https://github.com/grafana/loki/releases/download/v1.5.0/loki-linux-amd64.zip
        if [ $? -eq 0 ]; then
            break
        fi
    done
else
    unzip loki-linux-amd64.zip
    mv loki-linux-amd64 /usr/local/bin/lokid
fi

cat << EOF > /etc/loki/loki-local-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2018-04-15
      store: boltdb
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 168h

storage_config:
  boltdb:
    directory: /tmp/loki/index

  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOF

cat << EOF > /etc/systemd/system/lokid.service

[Unit]
Description=lokid service node
After=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/lokid  --config.file=/etc/loki/loki-local-config.yaml
Restart=always
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl restart lokid && systemctl status lokid && systemctl enable lokid