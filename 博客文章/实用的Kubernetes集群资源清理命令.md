# 实用的Kubernetes集群资源清理命令

1. Kubernetes 基础对象清理
- 清理 Evicted 状态的 Pod
```
kubectl get pods --all-namespaces -o wide | grep Evicted | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n
```
- 清理 Error 状态的 Pod
```
kubectl get pods --all-namespaces -o wide | grep Error | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n
```
- 清理 Completed 状态的 Pod
```
kubectl get pods --all-namespaces -o wide | grep Completed | awk '{print $1,$2}' | xargs -L1 kubectl delete pod -n
```
- 清理没有被使用的 PV
```
kubectl describe -A pvc | grep -E "^Name:.*$|^Namespace:.*$|^Used By:.*$" | grep -B 2 "<none>" | grep -E "^Name:.*$|^Namespace:.*$" | cut -f2 -d: | paste -d " " - - | xargs -n2 bash -c 'kubectl -n ${1} delete pvc ${0}'
```
- 清理没有被绑定的 PVC
```
kubectl get pvc --all-namespaces | tail -n +2 | grep -v Bound | awk '{print $1,$2}' | xargs -L1 kubectl delete pvc -n
```
- 清理没有被绑定的 PV
```
kubectl get pv | tail -n +2 | grep -v Bound | awk '{print $1}' | xargs -L1 kubectl delete pv
```
2. Docker 清理
- 清理 none 镜像
```
docker images | grep none | awk '{print $3}' | xargs docker rmi
```
- 清理不再使用的数据卷
```
docker volume rm $(docker volume ls -q)
docker volume prune
```
- 清理缓存
```
docker builder prune
```
- 全面清理
  - 删除关闭的容器、无用的存储卷、无用的网络、dangling 镜像（无 tag 镜像）
```
docker system prune -f 
```

