Linux禁止ping以及开启ping的方法
======================

Linux默认是允许Ping响应的，系统是否允许Ping由2个因素决定的 ：  
1. 内核参数
2. 防火墙 \
    需要2个因素同时允许才能允许Ping，2个因素有任意一个禁Ping就无法Ping
### **内核参数设置**
* 禁止ping设置  
  * 临时禁止ping命令如下所示
      ```
      # 如果想要临时允许的话只需要把下面的1换成0即可
      echo 1 >/proc/sys/net/ipv4/icmp_echo_ignore_all
      ```
  * 永久禁止ping命令如下所示(如果想要永久允许的话只需要把下面的1换成0即可)\
    在 **`/etc/sysctl.conf`** 文件中增加一行
    ```
    net.ipv4.icmp_echo_ignore_all=1
    ```
    * 修改完成后执行 **`sysctl -p`** 使新的配置生效

    ![微信截图_20200214233402.png](https://i.loli.net/2020/02/14/1lxhu6LRGZN3pqr.png)
  
### **防火墙设置** 
* (注意：此处的方法的前提使内核配置是默认值，也就是没有禁止ping)  
这里以iptables防火墙为例，其他防火墙操作方法自行百度。  
  * 允许ping设置  
    ```
    iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT  
    iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT  
    ```
  * 或者可以临时停止防火墙操作。  
    ```
    service iptables stop  
    ```
  * 禁止ping设置  
    ```
    iptables -A INPUT -p icmp --icmp-type 8 -s 0/0 -j DROP
    ```