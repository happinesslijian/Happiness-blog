k8s删除Terminating状态的命名空间
=======================
> 背景: 我们都知道在k8s中`namespace`有两种常见的状态，即Active和Terminating状态，其中后者一般会比较少见，只有当对应的命名空间下还存在运行的资源，但是该命名空间被删除时才会出现所谓的`terminating`状态，这种情况下只要等待k8s本身将命名空间下的资源回收后，该命名空间将会被系统自动删除。但是今天遇到命名空间下已没相关资源，但依然无法删除`terminating`状态的命名空间的情况，特此记录一下.
### 查看命名空间详情
```
$ kubectl  get ns  | grep nginx
nginx                  Terminating   1d1h

$ kubectl  get ns nginx -o yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Namespace","metadata":{"annotations":{},"name":"nginx"}}
  creationTimestamp: "2020-02-19T09:25:26Z"
  deletionTimestamp: "2020-02-20T10:10:43Z"
  name: nginx
  resourceVersion: "7733643"
  selfLink: /api/v1/namespaces/nginx
  uid: 39067ddf-56d7-4cce-afa3-1fbdbd223ab2
spec:
  finalizers:
  - kubernetes
status:
  phase: Terminating
```
### 查看该命名空间下的资源
```
# 查看k8s集群中可以使用命名空间隔离的资源
$ kubectl get all -n nginx
# 发现nginx命名空间下并无资源占用
```
### 尝试对命名空间进行删除
```
# 直接删除命名空间nginx
## 提示删除操作未能完成，说系统会在确定没用没用资源后将会被自动删除
$ kubectl  delete ns nginx
Error from server (Conflict): Operation cannot be fulfilled on namespaces "nginx": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.

# 使用强制删除(依然无法删除该命名空间)
$ kubectl  delete ns nginx --force --grace-period=0
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
Error from server (Conflict): Operation cannot be fulfilled on namespaces "nginx": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.
```
### 使用原生接口删除
```
# 获取namespace的详情信息
$ kubectl  get ns nginx  -o json > nginx.json

# 查看napespace定义的json配置
## 删除掉spec部分即可
$ cat nginx.json
{
    "apiVersion": "v1",
    "kind": "Namespace",
    "metadata": {
        "annotations": {
            "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"nginx\"}}\n"
        },
        "creationTimestamp": "2020-02-19T09:25:26Z",
        "deletionTimestamp": "2020-02-20T10:10:43Z",
        "name": "nginx",
        "resourceVersion": "7733643",
        "selfLink": "/api/v1/namespaces/nginx",
        "uid": "39067ddf-56d7-4cce-afa3-1fbdbd223ab2"
    },
    "spec": {
        "finalizers": [
            "kubernetes"
        ]
    },
    "status": {
        "phase": "Terminating"
    }
}

# 使用http接口进行删除
$ curl -k -H "Content-Type:application/json" -X PUT --data-binary @nginx.json https://x.x.x.x:6443/api/v1/namespaces/nginx/finalize
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "nginx",
    "selfLink": "/api/v1/namespaces/nginx/finalize",
    "uid": "39067ddf-56d7-4cce-afa3-1fbdbd223ab2",
    "resourceVersion": "7733643",
    "creationTimestamp": "2020-02-19T09:25:26Z",
    "deletionTimestamp": "2020-02-20T10:10:43Z",
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"v1\",\"kind\":\"Namespace\",\"metadata\":{\"annotations\":{},\"name\":\"nginx\"}}\n"
    }
  },
  "spec": {

  },
  "status": {
    "phase": "Terminating"
  }

# 再次查看namespace发现已经被删除了
$ kubectl  get ns  | grep nginx
```