# 说在前面

公司这边这周轮到我做技术汇报，前段时间一直在折腾docker的相关操作，所以打算讲讲docker的相关知识。

# Docker之前存在的问题

相信做过项目的大家都会遇到这样子的一种情况，软件开发的过程中，抛去刚开始的分析步骤以及开发流程，当软件开发完毕之后，这个时候需要将软件部署到对应的生产环境中，与之相对应的还有：开发环境、测试环境等，这些环境的配置部署都是完全一致的（仅仅只是配置不同）。 拿西瓜课表云端（此处仅指属于我开发的部分——Android客户端的检查更新以及数据统计部分）举例来说：每一次修改了代码，我需要在本地的IDE进行打包（ `./gradlew clean build` ），然后找到build目录下的 `libs` 目录中打包完成的jar包，然后将这个jar通过 `scp` 上传到对应的生产环境的服务器，再ssh到该服务器，执行 `java -jar xxx.jar`。而且当需要与Android端做联调的时候，整个的 `build-package-upload-stop-run` 的流程都会显得格外的繁琐。甚至还可能会出现其他问题：生产环境没安装jdk、某些依赖没有安装、环境变量没有配置等等。 因此需要一种能够将运行环境与软件一起打包带走的解决方案。

# 为什么不用虚拟机

虚拟机就是一种运行环境与软件打包带走的一种解决方案，我们只需要拿到镜像文件，然后将对应的虚拟机添加到 `VMWare` 或者 `Vitual Box` ，之后只需要简单的 开机 即可。当然，需要等那么一段时间。 玩过虚拟机的都清楚，虚拟机的运行需要先启动一个操作系统，然后才能启动里面的软件，而且虚拟机占用的资源甚至可能比我们运行的软件还大。此外，系统启动的必须步骤：登录无法绕过，而且启动虚拟机是真的～慢～～～～

# Docker

由于虚拟机的缺点，所以Linux发展出了Linux容器。 Docker即是Linux容器的一种封装。将软件以及运行环境打包进一个镜像文件中，通过分发这个镜像文件，可以自动大量的机器时候进行快速的部署。

## Docker的基本概念

### Docker镜像（Image）

Docker镜像可以理解为Java的 类 ，镜像中包含了需要运行的软件以及这个软件需要的运行环境。Docker镜像可以用来创建容器，容器可以理解为镜像运行时的实例，也就是 对象 。 同编程语言一样，这个镜像是可以 继承 的，我们可以在一个镜像的基础进行简单的修改或者扩展，创建一个新的镜像。一般我们都是提供需要运行的软件，然后使用别人做好的镜像，创建一个新的运行镜像，这样我们能够剩下很多重复的环境配置步骤。

### Docker容器（Container）

容器是通过镜像创建的运行时实例，它可以被启动、开始、停止、删除。容器之间是相互隔离的。容器本身也是一个文件，默认情况下，停止一个容器不会自动删除该文件，这样子可以在下一次直接启动该容器而不是创建一个新的容器。

### Docker注册服务器（Registry）

正如其名，Docker仓库是用来存储多个Docker镜像的仓库，我们可以将这个仓库放到公共网络上，这样其他人可以通过公共网络拉去仓库中的Docker镜像。Docker Hub是Docker官方提供的注册服务器。

### Docker仓库

和Docker Registry不同，Docker仓库指的是同一类型的镜像的仓库。 一个Registry可以有多个Docker仓库，一个Docker仓库有多个Docker镜像，但是一个Docker仓库中只能有同一类型的Docker镜像，同一类型指的是名字相同。比如： hello-world:1.0 和 hello-world:2.0 属于同一个Docker仓库，和 helloworld:1.0 不属于同一个仓库。而 : 后面的版本号称为标签（tag），默认标签是 latest。

### Dockerfile

上面的概念了解了之后，我们就会想问，Docker镜像是如何制作出来的？这就需要编写Dockerfile。Dockerfile是一个文件，里面定义了镜像的配置。 Dockerfile示例:

```dockerfile
#This is a Dockerfile
#Author:liming
#第一行必须指定基础镜像
FROM ubuntu
#维护者信息
MAINTAINER <xxxx@xxxx.xxx>
#镜像的操作指令
RUN echo "Hello World"
#容器启动时的指令
CMD /usr/sbin/nginx

```

* FROM Dockerfile的第一条指令必须是FROM指令，用于指定基础镜像，也就是我们前面所提到的 父类。
* MAINTAINER 指定维护者的信息。
* RUN 自动shell终端执行的命令。
* EXPOSE 暴露的端口号，启动时可以通过 `-p` 或 `-P` 进行端口绑定。
* ENV 指定一个环境变量，可以被后续的RUN命令使用。容器内部也可以使用环境变量。
* ADD 复制指定的文件到容器中，可以是一个路径、一个tar文件或者url。
* VOLUME 挂载目录到容器中，一般用于存储需要持久化存储的数据。
* USER 指定运行容器时的用户名，后续的RUN也会使用该用户名。
* WORKDIR 执行工作空间，可以理解为 `cd` 。
* COPY 复制本地目录的文件到容器中。当ADD的文件是本地文件时，推荐使用COPY命令。
* CMD 指定容器的启动命令，只能有一条CMD命令，用户启动容器时如果指定运行命令，那么会覆盖Dockerfile中的CMD命令。
* ENTRYPOINT 指定容器启动后的命令，同CMD一样，只能有一条，多条时只会执行最后一条。

在Dockerfile所在目录，通过 `docker build -t "${tag}"` 命令即可构建属于自己的Docker镜像，Docker会根据Dockerfile指定的命令进行构建。 **值得注意的一点是：Dockerfile会根据上一个命令的执行结果生成一个镜像，然后继续执行下一个命令。** 这样就能将Docker镜像的构建过程缓存起来，方便下一次执行的时候重复使用。因此，为了有效的利用缓存，需要保持Dockerfile一致，并且尽量在末尾进行修改。 **在Dockerfile中可以通过EXPOSE指定暴露的端口，也可以在此处进行端口的映射，但是不推荐这样指定。**

关于Dockerfile的配置，推荐阅读一下两篇文章： [Dockerfile最佳实践（一）](http://dockone.io/article/131)

[Dockerfile最佳实践（二）](http://dockone.io/article/132)

## 安装

安装步骤应该都被各位写烂了，所以在这里就不重复写了，可以参考[官方的文档](https://docs.docker.com/install/)进行安装（官方的才是最好的）。

## 常用命令
- 镜像常用命令
```
docker pull [镜像名称:版本]  拉取镜像

docker images 镜像列表

docker rmi [镜像名称:版本] 删除镜像
 
docker history [镜像名称] 镜像操作记录
 
docker tag [镜像名称:版本][新镜像名称:新版本]

docker inspect [镜像名称:版本] 查看镜像详细
 
docker search [关键字] 搜索镜像

docker login 镜像登陆
```
- 容器常用命令
```
docker ps -a 容器列表(所有容器)

docker ps  查看所有(运行的)容器

docker exec -it <id> bash 以 bash 命令进入容器内

docker run -it --name [容器名称][镜像名称:版本] bash 启动容器并进入

docker logs 查看容器日志

docker top <container_id> 查看容器最近的一个进程

docker run -it --name [容器名称] -p 8080:80  [镜像名称:版本] bash 端口映射

docker rm <container_id> 删除容器

docker stop <container_id> 停止容器

docker start <container_id> 开启容器

docker restart <container_id> 重启容器

docker inspect <container_id> 查看容器详情

docker commit [容器名称] my_image:v1.0  容器提交为新的镜像
```
