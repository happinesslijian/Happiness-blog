# 如何将 Helm Chart 转换为 Kubernetes YAML

在本博客中，您将学习将现有 Helm 图表模板转换为 Kubernetes YAML 清单。  
那么，为什么有人想要将 Helm 模板转换为 Kubernetes 清单呢？  
如果您查看社区 helm 图表，有时初学者会混淆图表安装的所有组件。  
因此，如果您想了解社区 helm 图表或了解 Helm 图表中的每个组件，您可以将 helm 图表转换为 Kubernetes 清单。  
一旦你有了 Kubernetes YAML 文件，就很容易理解和理解 helm chart。  
### 将 Helm Chart 转换为 Kubernetes YAML  
将 Helm 图表转换为 kubernetes YAML 非常简单。  
您可以使用 helm 本机命令来实现此目的。
在 helm 中有一个命令叫做`helm template`. 使用 `template` 命令，您可以将任何 helm 图表转换为 YAML 清单。  
生成的清单文件将在 helm 中设置所有默认值`values.yaml`.  
确保您已 [安装helm](https://devopscube.com/install-configure-helm-kubernetes/)以执行模板命令。  
我们将使用 Vault 社区掌舵图来演示这一点。  
确保首先添加 helm repo。  
添加 Helm 存储库：  
```
helm repo add cetic https://cetic.github.io/helm-charts
```
以下命令将zabbix helm chart 转换为 YAML。
```
helm template zabbix cetic/zabbix --output-dir zabbix-manifests/helm-manifests
```
在上面的命令中，cetic/zabbix是图表名称。  
zabbix-manifests/helm-manifests是存储 YAML 的输出目录。
像这样，您可以将任何 helm chart 转换为 Kubernetes YAML 文件。  
生成的文件在  
```
/root/zabbix-manifests/helm-manifests/zabbix/templates
/root/zabbix-manifests/helm-manifests/zabbix/charts/postgresql/templates/primary
```


[原文链接](https://devopslearners.com/how-to-convert-helm-chart-to-kubernetes-yaml-fbe6d6722f6)
[原文链接](https://scriptcrunch.com/convert-helm-chart-kubernetes-yaml/)