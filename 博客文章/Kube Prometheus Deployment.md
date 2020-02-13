> 部署`coreos`的`kube-prometheus`,直接开门见山，不多BB。

1. clone code
    
    ```
    git clone https://github.com/coreos/kube-prometheus.git --depth 1
    ```
    
2. 分类
    
    ```
    $ ls
    alertmanager-alertmanager.yaml                              prometheus-adapter-clusterRoleBindingDelegator.yaml
    alertmanager-secret.yaml                                    prometheus-adapter-clusterRoleBinding.yaml
    alertmanager-serviceAccount.yaml                            prometheus-adapter-clusterRoleServerResources.yaml
    alertmanager-serviceMonitor.yaml                            prometheus-adapter-clusterRole.yaml
    alertmanager-service.yaml                                   prometheus-adapter-configMap.yaml
    grafana-dashboardDatasources.yaml                           prometheus-adapter-deployment.yaml
    grafana-dashboardDefinitions.yaml                           prometheus-adapter-roleBindingAuthReader.yaml
    grafana-dashboardSources.yaml                               prometheus-adapter-serviceAccount.yaml
    grafana-deployment.yaml                                     prometheus-adapter-service.yaml
    grafana-serviceAccount.yaml                                 prometheus-clusterRoleBinding.yaml
    grafana-serviceMonitor.yaml                                 prometheus-clusterRole.yaml
    grafana-service.yaml                                        prometheus-operator-serviceMonitor.yaml
    kube-state-metrics-clusterRoleBinding.yaml                  prometheus-prometheus.yaml
    kube-state-metrics-clusterRole.yaml                         prometheus-roleBindingConfig.yaml
    kube-state-metrics-deployment.yaml                          prometheus-roleBindingSpecificNamespaces.yaml
    kube-state-metrics-roleBinding.yaml                         prometheus-roleConfig.yaml
    kube-state-metrics-role.yaml                                prometheus-roleSpecificNamespaces.yaml
    kube-state-metrics-serviceAccount.yaml                      prometheus-rules.yaml
    kube-state-metrics-serviceMonitor.yaml                      prometheus-serviceAccount.yaml
    kube-state-metrics-service.yaml                             prometheus-serviceMonitorApiserver.yaml
    node-exporter-clusterRoleBinding.yaml                       prometheus-serviceMonitorCoreDNS.yaml
    node-exporter-clusterRole.yaml                              prometheus-serviceMonitorKubeControllerManager.yaml
    node-exporter-daemonset.yaml                                prometheus-serviceMonitorKubelet.yaml
    node-exporter-serviceAccount.yaml                           prometheus-serviceMonitorKubeScheduler.yaml
    node-exporter-serviceMonitor.yaml                           prometheus-serviceMonitor.yaml
    node-exporter-service.yaml                                  prometheus-service.yaml
    prometheus-adapter-apiService.yaml                          setup
    prometheus-adapter-clusterRoleAggregatedMetricsReader.yaml
    
    $ mkdir -pv adapter alertmanager grafana kube-state-metrics node-exporter prometheus serviceMonitor
    
    $ mv grafana-* grafana/
    $ mv *serviceMonitor* serviceMonitor/
    $ mv kube-state-metrics-* kube-state-metrics/
    $ mv alertmanager-* alertmanager/
    $ mv node-exporter-* node-exporter/
    $ mv prometheus-adapter* adapter/
    $ mv prometheus-* prometheus/
    
    $ ls
    adapter  alertmanager  grafana  kube-state-metrics  node-exporter  prometheus  setup
    ```
    
3. deploy manifests/setup
    ```
    $ kubectl apply -f manifests/setup
    ```
    
4. deploy manifests
    ```
    for i in `ls |grep -v setup`; do kubectl apply -f $i/; done
    ```
5. ingress准备工作
   ```
   yum -y install httpd
   htpasswd -bc auth admin admin
   kubectl create secret generic yohu --from-file=auth -n monitoring
   ``` 

6. 配置ingress规则
```    
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: dev-monitoring-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - yoho.com
    secretName: yoho
  rules:
  - host: dev-alertmanager.yoho.com
    http:
      paths:
      - path:
        backend:
          serviceName: alertmanager-main
          servicePort: 9093
  - host: dev-grafana.yoho.com
    http:
      paths:
      - path:
        backend:
          serviceName: grafana
          servicePort: 3000
  - host: dev-prometheus-k8s.yoho.com
    http:
      paths:
      - path:
        backend:
          serviceName: prometheus-k8s
          servicePort: 9090
```
7. 查看ingress
```
[root@k8s-master ~]# kubectl get ing -n monitoring
NAME                     HOSTS                                                                        ADDRESS         PORTS     AGE
dev-monitoring-ingress   dev-alertmanager.yoho.com,dev-grafana.yoho.com,dev-prometheus-k8s.yoho.com   10.244.114.18   80, 443   12m
```
> grafana 默认用户名密码 admin:admin
