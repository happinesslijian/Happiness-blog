# 基本身份验证

本示例说明如何使用包含由生成的文件的密钥在Ingress规则中添加身份验证`htpasswd`。生成的文件的名称很重要`auth`（实际上-机密具有密钥`data.auth`），否则入口控制器将返回503。

```
$ htpasswd -c auth foo
New password: <bar>
New password:
Re-type new password:
Adding password for user foo
```

```
$ kubectl create secret generic basic-auth --from-file=auth
secret "basic-auth" created
```

```
$ kubectl get secret basic-auth -o yaml
apiVersion: v1
data:
  auth: Zm9vOiRhcHIxJE9GRzNYeWJwJGNrTDBGSERBa29YWUlsSDkuY3lzVDAK
kind: Secret
metadata:
  name: basic-auth
  namespace: default
type: Opaque
```

```
echo "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-with-auth
  annotations:
    # type of authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    # name of the secret that contains the user/password definitions
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # message to display with an appropriate context why the authentication is required
    nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - foo'
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /
        backend:
          serviceName: http-svc
          servicePort: 80
" | kubectl create -f -
```
