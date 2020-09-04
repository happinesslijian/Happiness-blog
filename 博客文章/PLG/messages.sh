#!/bin/bash
echo -e '\033[1;31m 本脚本收集部署主机的/var/log/messages日志信息 \033[0m'
echo -n "请输入被索引主机的主机名:"
read hostname

echo -e '\033[1;31m 写入配置文件到/etc/promtail/promtail-local-config.yaml \033[0m'
cat >> /etc/promtail/promtail-local-config.yaml << EOF
- job_name: 10.20.80.207
  static_configs:
  - targets:
      - localhost
    labels:
      job: ${hostname}-messages-logs
      __path__: /var/log/messages
EOF
systemctl restart promtail 
echo -e '\033[1;31m 执行完毕,请查看Loki  job选项 \033[0m'
exit