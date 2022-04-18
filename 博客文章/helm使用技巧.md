### helm小技巧

```
# 添加 Helm 存储库
helm repo add kedacore https://kedacore.github.io/charts


# 查找某一个存储库
helm search repo kedacore


# 如果有修改values.yaml文件需求的话(比如指定后端storageclass存储)则执行如下
#已经解压的目录
helm pull kedacore/keda --untar 


#未解压的压缩包
helm pull kedacore/keda   
cd keda


#指定values.yaml部署
helm install keda -f values.yaml . -n keda         


# 查看状态
helm status keda -n keda
```