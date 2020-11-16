### centos7安装puppeteer并使用zignis爬取文章
[关于puppeteer](https://github.com/vipzhicheng/zignis-plugin-read)

1.安装nodejs 下面使用yum来进行安装
```
# 先确认系统是否已经安装了epel-release包
$ yum info epel-release
# 如果有输出有关epel-release的已安装信息，则说明已经安装，如果提示没有安装或可安装，则安装
$ sudo yum install epel-release -y
# 安装完后，就可以使用yum命令安装nodejs了，安装的一般会是较新的版本，并且会将npm作为依赖包一起安装
$ sudo yum install nodejs -y
# 验证
$ node -v
v6.17.1
```
2.升级nodejs(使用puppeteer版本不能低于7.6)
```
# 清除node缓存
$ sudo npm cache clean -f  
# 安装node版本管理工具'n'
$ sudo npm install n -g
# 使用版本管理工具安装指定node或者升级到最新node版本
$ sudo n stable (安装node最新版本)
# 使用node -v查看node版本，如果版本号改变为你想要的则升级成功
$ node -v
# 若版本号未改则还需配置node环境变量
# cd进入/usr/local/n/versions/node/ 你应该能看到你刚通过n安装的node版本这里如：12.16.0
$ cd /usr/local/n/versions/node/
# 编辑/etc/profile;
$ vim /etc/profile
# 将node安装的路径(这里为：/usr/local/n/versions/node/12.16.0)添加到文件末尾
$ export PATH="$PATH:/usr/local/n/versions/node/12.16.0"
# wq退出保存文件，编译/etc/profile;
$  source /etc/profile
# 再次使用node -v查看node版本
$ node -v
v12.16.0
```
> 第二步如果不成功可以使用如下：
```
yum install -y gcc gcc-c++ && wget https://npm.taobao.org/mirrors/node/v10.14.1/node-v10.14.1-linux-x64.tar.gz && tar xf node-v10.14.1-linux-x64.tar.gz -C /usr/local/ && mv /usr/local/node-v10.14.1-linux-x64 /usr/local/node && 
cat << EOF >> /etc/profile
export NODE_HOME=/usr/local/node  
export PATH=$NODE_HOME/bin:$PATH
EOF
source /etc/profile && node -v && npm -v
```
3.用cnpm安装puppeteer
```
# 安装cnpm(时间非常久,取决你的网络,建议喝杯咖啡)
npm install -g cnpm --registry=https://registry.npm.taobao.org
# 使用cnpm安装puppeteer
cnpm i puppeteer
```
4.跳过puppeteer安装zignis zignis-plugin-read
```
# 跳过puppeteer安装zignis zignis-plugin-read(时间非常久,取决你的网络,建议吃点水果)
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true npm i -g zignis zignis-plugin-read
```
5.[使用方式详见](https://github.com/vipzhicheng/zignis-plugin-read#%E5%AE%89%E8%A3%85%E5%92%8C%E4%BD%BF%E7%94%A8)
