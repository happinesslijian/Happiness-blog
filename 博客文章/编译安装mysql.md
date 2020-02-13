# 编译安装mysql5.6.36
[下载mysql5.6.36](http://nextcloud.cpolar.cn/s/PZ5C8YS5iJSc3Gb)
- 安装依赖
```
yum install ncurses-devel libaio-devel cmake gcc gcc-c++ -y
rpm -qa ncurses-devel libaio-devel cmake
```
- 创建用户
```
useradd -s /sbin/nologin -M mysql
id mysql
```
- 解压并编译安装
```
tar xf mysql-5.6.36.tar.gz
cd mysql-5.6.36

cmake . -DCMAKE_INSTALL_PREFIX=/opt/mysql \
-DMYSQL_DATADIR=/opt/mysql/data \
-DMYSQL_UNIX_ADDR=/opt/mysql/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_EXTRA_CHARSETS=all \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
-DWITH_ZLIB=bundled \
-DWITH_SSL=bundled \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_EMBEDDED_SERVER=1 \
-DENABLE_DOWNLOADS=1 \
-DWITH_DEBUG=0

echo $?

make && make install
```
- 准备环境分配权限更改变量
```
ll /opt/mysql/
cp support-files/my*.cnf /etc/my.cnf

chmod +x /opt/mysql/scripts/mysql_install_db
yum -y install autoconf
/opt/mysql/scripts/mysql_install_db --basedir=/opt/mysql/ --datadir=/opt/mysql/data --user=mysql
chown -R mysql.mysql /opt/mysql/
cp support-files/mysql.server /etc/init.d/mysqld
mkdir /opt/mysql/tmp -p
chown -R mysql.mysql /opt/mysql/
chmod 700 /etc/init.d/mysqld
chkconfig mysqld on
chkconfig --list mysqld
/etc/init.d/mysqld start
netstat -lntup|grep 330

echo 'PATH=/opt/mysql/bin/:$PATH' >>/etc/profile
tail -1 /etc/profile
source /etc/profile
echo $PATH
```
- 验证mysql
```
mysql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'passwd' WITH GRANT OPTION;
flush privileges;
```
- mysql设置密码并更新权限
```
mysqladmin -u root password pa88w0rd
mysql -u root -p
use mysql
SELECT User, Password, Host FROM user;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT User, Password, Host FROM user;
```
