# Tengine

[TOC]

## <u>文档标识</u>

| 文档名称 | Tengine  |
| -------- | -------- |
| 版本号   | <V1.0.0> |

## <u>文档修订历史</u>

| 版本   | 日期       | 描述   | 文档所有者 |
| ------ | ---------- | ------ | ---------- |
| V1.0.0 | 2022.11.11 | create | 杨丝雨     |
|        |            |        |            |
|        |            |        |            |



## <u>服务器规划</u>

| IP地址 | 服务器配置 | OS   | remarks |
| ------ | ---------- | ---- | ------- |
|        |            |      |         |



## <u>路径规划</u>

| 路径                              | 描述         | 文件名        | remarks      |
| --------------------------------- | ------------ | ------------- | ------------ |
| /usr/local/nginx/                 | 安装路径     |               |              |
| /usr/local/nginx/logs             | 日志路径     |               |              |
| /usr/local/nginx/sbin/            | 二进制文件   | nginx         |              |
| /lib/systemd/system/nginx.service | 启动文件配置 | nginx.service |              |
| /usr/local/nginx/conf/            | 配置文件路径 | nginx.conf    | 默认配置文件 |
|                                   |              |               |              |

## <u>端口规划</u>

| 端口 | 协议 | remrks       |
| ---- | ---- | ------------ |
| 80   | tcp  | 默认开放端口 |
|      |      |              |
|      |      |              |

## <u>软件包</u>

| 安装包  | 版本   | 下载地址                                                |
| ------- | ------ | ------------------------------------------------------- |
| tengine | v2.3.3 | http://tengine.taobao.org/download/tengine-2.3.3.tar.gz |
|         |        |                                                         |
|         |        |                                                         |



## <u>相关文档参考</u>

[Tengine官方文档]: http://tengine.taobao.org/book/chapter_02.html
[Tengine官方下载地址]: http://tengine.taobao.org/download_cn.html
[Tengine安装配置文档]: https://www.cnblogs.com/dooor/p/tengine.html

> ​		Tengine是由淘宝网发起的Web服务器项目。它在Nginx的基础上，针对大访问量网站的需求，添加了很多高级功能和特性。Tengine的 性能和稳定性已经在大型的网站如淘宝网，天猫商城等得到了很好的检验。它的最终目标是打造一个高效、稳定、安全、易用的Web平台。

### 安装Tengine

#### 1.1	安装依赖

系统依赖组件 `gcc gcc-c++  pcre pcre-devel  zlib zlib-devel  openssl openssl-devel wget`

安装：

```shell
yum install gcc gcc-c++  pcre pcre-devel  zlib zlib-devel  openssl openssl-devel wget -y
```

#### 1.2	下载安装包

安装包下载[地址](http://tengine.taobao.org/download_cn.html)

```shell
cd /usr/local/src && wget http://tengine.taobao.org/download/tengine-2.3.3.tar.gz && tar -zxvf tengine-2.3.3.tar.gz && cd tengine-2.3.3
```

#### 1.3	编译安装

```shell
./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_stub_status_module --with-http_gzip_static_module --with-pcre

echo $?
# 如果输出0则下一步
make -j4 && make install
# -j 则是调用多核心，进行并行编译。建议是cpu核心的两倍
```

#### 1.4	启动

##### 1.4.1	设置开机自启

nginx正常的启动｜重载｜停止｜检测

```shell
/usr/local/nginx/sbin/nginx					# 启动 -c 制定启动配置文件
/usr/local/nginx/sbin/nginx -s reload			# 重新加载
/usr/local/nginx/sbin/nginx -s stop			# 停止
/usr/local/nginx/sbin/nginx -t			# 检测配置文件
```



```shell
# 系统用户登录启动服务
vi /lib/systemd/system/nginx.service
```

添加以下配置

```shell
[Unit]
Description=The nginx HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

修改可执行权限

```shell
chmod 745 /lib/systemd/system/nginx.service
```

重新加载配置

```shell
systemctl daemon-reload
```

设置开机自启

```shell
# 设置开机启动
systemctl enable nginx.service
#停止开启启动
systemctl disable nginx.service
```

##### 1.4.2	启动

```shell
#启动nginx服务    
systemctl start nginx.service
#查看服务当前状态 
systemctl status nginx.service
#重新启动服务     
systemctl restart nginx.service
#查看所有已启动的服务  
systemctl list-units --type=service
```

### 日志切割

#### 1.1	创建脚本

创建一个shell可执行文件: `cut_my_log.sh`，内容为:

```shell
#! /bin/bash
#原日志存放路径
LOG_PATH="/usr/local/nginx/logs/"
#按天切割
RECORD_TIME+$(date -d "yesterday" +%Y-%m-%d)
PID=/usr/local/nginx/logs/nginx.pid
#文件命名
mv ${LOG_PATH}/access.log ${LOG_PATH}/access.${RECORD_TIME}.log
mv ${LOG_PATH}/error.log ${LOG_PATH}/error.${RECORD_TIME}.log
#先Nginx主进程发送型号，用于重新打开日志文件
kill -USR1 'cat $PID'
```

#### 1.2	配置

```shell
# 1.为cut_my_log.sh添加可执行的权限
chmod +x cut_my_log.sh
# 2.测试日志切割后的结果
./chmod +x cut_my_log.sh
# 3.添加定时任务
yum install crontabs
# 4.编辑并添加一行新的任务：
crontabs -e 
# 内容如下
0 1 * * * /usr/local/nginx/sbin/cut_my_log.sh
# 重新定时任务
service crond restart

#定时任务其他命令
service crond start
service crond stop
service crond restart
service crond reload
crontab -e //编辑任务
crontab -l //查看任务列表
```

> **定时表达式**
>
> Cron表达式分为5或6个域，每个域含义

![img](https://img2022.cnblogs.com/blog/907818/202202/907818-20220226144832291-1308392830.jpg?watermark/2/text/aHR0cHM6Ly93d3cuZHZvbXUuY29t/font/5a6L5L2T/fontsize/25/fill/I0ZGMDAwMA==/dissolve/50/gravity/SouthEast)

常用表达式

```shell
*/1 * * * * #每分钟执行
59 23 * * * #每日晚上23：59执行
0 1 * * *   #每日1点执行
```

### 配置解析

```shell
# 操作用户
#user  nobody;

# Nginx工作进程 通常与CPU数量相同
worker_processes  1;

# 错误日志存放路径，日志级别：info notice warn error crit
error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
#error_log  "pipe:rollback logs/error_log interval=1d baknum=7 maxsize=2G";

# NGINX进程号
pid        logs/nginx.pid;

#配置工作模式以及连接数
events {
    #默认使用epoll Linux 2.6以上版本内核中的高性能网络I/O模型，如果跑在FreeBSD上面，就用kqueue模型。
    use epoll;

    # 并发总数是 worker_processes 和 worker_connections 的乘积
    # 即 max_clients = worker_processes * worker_connections
    # 并发连接总数需小于系统可以打开的文件句柄总数（cat /proc/sys/fs/file-max）

    # 在设置了反向代理的情况下，max_clients = worker_processes * worker_connections / 4  为什么
    # 为什么上面反向代理要除以4，应该说是一个经验值根据以上条件，正常情况下的Nginx Server可以应付的最大连接数为：
    # 4 * 8000 = 32000worker_connections 值的设置跟物理内存大小有关
    # 因为并发受IO约束，max_clients的值须小于系统可以打开的最大文件数
    worker_connections  10240;
}

# http模块相关配置
http {
    # 导入外部文件
    include       mime.types;
    #  默认文件类型
    default_type  application/octet-stream;
    # 默认编码
    charset utf-8; 
    # 上传文件大小限制
    client_header_buffer_size 32k; 

    # 请求日志内容
    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    # 请求日志存放路径
    #access_log  "pipe:rollback logs/access_log interval=1d baknum=7 maxsize=2G"  main;

    # 文件高效传输。sendfile指令指定nginx是否调用sendfile函数来输出文件，对于普通应用设为on，
    # 如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。
    sendfile        on;
    # 当数据包累计到一定大小再发送，需sendfile开启
    #tcp_nopush     on;
    #开启目录列表访问，适合下载服务器，默认关闭。
    #autoindex on; 

    #客户端连接Nginx后保存连接时间，浏览器默认60s
    keepalive_timeout  65;


    # 内容传输是否压缩，建议开启.可提升传输显效率节省带宽
    #gzip  on;
    #限制最小压缩，小于100字节不会压缩
    gzip_min_length 100;
    #定义压缩级别，范围1~9（压缩比文件越大，压缩越多，但是CPU使用会越多）
    gzip_comp_level 3;
    # 给CDN和代理服务器使用，针对相同url，可以根据头信息返回压缩和非压缩副本 
    #gzip_vary on; 
    #定义压缩文件的类型，默认就已经包含text/html，所以下面就不用再写了，写上去也不会有问题，但是会有一个warn。
    gzip_types text/plain application/javascript application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png application/json
 
    server{
        listen  80;
        # 多个域名用空格隔开
        server_name localhost;
        # 跨域设置
        # 允许跨域请求的域，*代表所有
        add_header 'Access-Control-Allow-Origin' *;
        # 允许带上cookie请求
        add_header 'Access-Control-Allow-Credentials' 'true';
        # 允许请求的方法
        add_header 'Access-Control-Allow-Methods' *;
        # 循序请求的头
        add_header 'Access-Control-Allow-Headers' *;
        
        # 防盗链配置,只允许*.imooc.com来源
        valid_referers *.imooc.com
        # 非法引入会进入下方判断
        if($invalid_referer){
            return 404;
        }
        # 路由（优先级：= > ^~ > ~|~* >  /|/dir/）
        #  匹配规则 ：
        #       = 精准匹配
        #       正则表达式： 
        #               *代表不区分大小写
        location / {
            root    html;
            index   index.html;
        }
        #方式1：所有请求/static路径会映射服务器路径/home/static路径下
        location /static {
            root    /home;
        }
        #【建议使用】方式2：通过别名 所有请求/ss路径会映射/home/static路径下
        location /ss {
            alias   /home/static;
        }
        error_page  500 502 503 504  /50x.html;
        localtion /50x.html {
            root html;
        }
    }
    
    ##
     #NGINX集群配置
     # weigth:权重，默认1；
     # max_conns:最大连接数，如果worker_processes配置后会受影响使用，
     #            此参数需在NGINX1.11.5之后版本使用，之前版本限制只能在商业版使用 
     #            操作最大连接数 返回502
     # max_fails、fail_timeout、slow_start 都必须在2个及以上服务器中使用  
     # slow_start:一定时间后缓慢加入集群，需配合weigth使用。在商业版中才能用
     # down :备用机，当其他主机挂掉后 访问会达到备用机
     # 
     ##
    upstream tomcats {
        #ip_hash;#通过IP hash取模，通过IP前3段（192.168.23）取模。注释此配置默认使用轮询
        server 192.168.88.101:8080 weigth=1 max_conns=2 slow_start=60s;
        server 192.168.88.102:8080 weigth=1 down;
        server 192.168.88.103:8080 weigth=1; 
        
        #keepalive：保持连接数，提高系统吞吐量
        keepalive 32;
    }
    ##
      # NGINX端缓存设置
      #      proxy_cache_path:设置缓存保存的目录
      #      keys_zone：设置共享内存以及占用的空间大小
      #      max_size：设置缓存大小
      #      inactive：超过此时间，则缓存自动清理
      #      use_temp_path：关闭临时目录
      ##
      proxy_cache_path   /usr/local/nginx/upsteam_cache keys_zone=mycache:5m max_size=1g inactive=300s use_temp_path=off;
    server {
        listen    80;
        server_name   www.tomcats.com;
        localtion / {
            proxy_pass   http://tomcats;
            
            # 开启缓存
            proxy_cache mycache;
            # 针对200和304状态码的缓存设置过期时间
            proxy_cache_valid 200 304 8h;
            
            # 配合keepalive使用
            proxy_http_version 1.1;
            # 配合keepalive使用
            proxy_set_header Connection "";
        }
    }
}
```

### 反向代理

#### 1.1	概念

> 通常的代理服务器，只用于代理内部网络对Internet的连接请求，客户机必须指定代理服务器,并将本来要直接发送到Web服务器上的http请求发送到代理服务器中由代理服务器向Internet上的web服务器发起请求，最终达到客户机上网的目的。
> **反向代理**（**Reverse Proxy**）方式是指以代理服务器来接受internet上的连接请求，然后将请求转发给内部网络上的服务器，并将从服务器上得到的结果返回给internet上请求连接的客户端，此时代理服务器对外就表现为一个反向代理服务器。

![img](https://img2022.cnblogs.com/blog/907818/202202/907818-20220226144832328-710976539.jpg?watermark/2/text/aHR0cHM6Ly93d3cuZHZvbXUuY29t/font/5a6L5L2T/fontsize/25/fill/I0ZGMDAwMA==/dissolve/50/gravity/SouthEast)

经典方向代理结构

![img](https://img2022.cnblogs.com/blog/907818/202202/907818-20220226144832304-806981716.jpg?watermark/2/text/aHR0cHM6Ly93d3cuZHZvbXUuY29t/font/5a6L5L2T/fontsize/25/fill/I0ZGMDAwMA==/dissolve/50/gravity/SouthEast)

#### 1.2	反向代理配置

##### 1.2.1	upstream

反向代理配合upstream使用

```shell
upstream httpds {
    server 192.168.43.152:80;
    server 192.168.43.153:80;
}
```

##### 1.2.2	weight(权重)

指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。

```shell
upstream httpds {
    server 127.0.0.1:8050       weight=10 down;
    server 127.0.0.1:8060       weight=1;
    server 127.0.0.1:8060       weight=1 backup;
}
```

- down：表示当前的server暂时不参与负载
- weight：默认为1.weight越大，负载的权重就越大。
- backup： 其它所有的非backup机器down或者忙的时候，请求backup机器。

- [ ] max_conns
  可以根据服务的好坏来设置最大连接数，防止挂掉，比如1000，我们可以设置800。

```shell
upstream httpds {
    server 127.0.0.1:8050    weight=5  max_conns=800;
    server 127.0.0.1:8060    weight=1;
}
```

- [ ] max_fails、 fail_timeout

max_fails:失败多少次 认为主机已挂掉则，踢出，公司资源少的话一般设置2-3次，多的话设置1次
max_fails=3 fail_timeout=30s代表在30秒内请求某一应用失败3次，认为该应用宕机，后等待30秒，这期间内不会再把新请求发送到宕机应用，而是直接发到正常的那一台，时间到后再有请求进来继续尝试连接宕机应用且仅尝试1次，如果还是失败，则继续等待30秒...以此循环，直到恢复。

```shell
upstream httpds {
    server 127.0.0.1:8050    weight=1  max_fails=1  fail_timeout=20;
    server 127.0.0.1:8060    weight=1;
}
```

##### 1.3	负载均衡算法

**轮询+weight、 ip_hash、 url_hash 、least_conn、 least_time**	

##### 1.4	监控检查

配置一个status的location

```shell
location /status {
    check_status;
}
```

在upstream配置如下

```shell
check interval=3000 rise=2 fall=5 timeout=1000 type=http;
check_http_send "HEAD / HTTP/1.0\r\n\r\n";
check_http_expect_alive http_2xx http_3xx;
```



## <u>附录：Tengine & Nginx性能测试</u>

```shell
http://tengine.taobao.org/document_cn/benchmark_cn.html

# 结论:
    Tengine相比Nginx默认配置，提升200%的处理能力。
    Tengine相比Nginx优化配置，提升60%的处理能力。
```

## <u>附录：功能</u>

-  继承Nginx-1.6.2的所有特性，**兼容Nginx的配置**；
-  **动态模块加载（DSO）支持**。加入一个模块不再需要重新编译整个Tengine；
-  支持SO_REUSEPORT选项，**建连性能**提升为官方nginx的三倍；
-  支持SPDY v3协议，自动检测同一端口的SPDY请求和HTTP请求；
-  流式上传到HTTP后端服务器或FastCGI服务器，大量减少机器的I/O压力；
-  **更加强大的负载均衡能力**，包括一致性hash模块、会话保持模块，还可以对后端的服务器进行主动健康检查，根据服务器状态自动上线下线，以及动态解析upstream中出现的域名；
-  输入过滤器机制支持。通过使用这种机制Web应用防火墙的编写更为方便；
-  支持设置proxy、memcached、fastcgi、scgi、uwsgi在后端失败时的重试次数
-  动态脚本语言Lua支持。扩展功能非常高效简单；
-  支持管道（pipe）和syslog（本地和远端）形式的日志以及日志抽样；
-  支持按指定关键字(域名，url等)收集Tengine运行状态；
-  组合多个CSS、JavaScript文件的访问请求变成一个请求；
-  自动去除空白字符和注释从而减小页面的体积
-  自动根据CPU数目设置进程个数和绑定CPU亲缘性；
-  监控系统的负载和资源占用从而对系统进行保护；
-  显示对运维人员更友好的出错信息，便于定位出错机器；
-  更强大的防攻击（访问速度限制）模块；
-  更方便的命令行参数，如列出编译的模块列表、支持的指令等；
-  可以根据访问文件类型设置过期时间

## <u>附录：nginx配置文件优化可行方案</u>

```shell
user www www;
#用户&组
worker_processes auto;
#通常是CPU核的数量存储数据的硬盘数量及负载模式,不确定时将其设置为可用的CPU内核数（设置为“auto”将尝试自动检测它）
error_log /usr/local/nginx/logs/error.log crit;
pid /usr/local/nginx/logs/nginx.pid;
#指定pid文件的位置,默认值就可以
 
worker_rlimit_nofile 65535;
#更改worker进程的最大打开文件数限制
events {
use epoll;
multi_accept on;
#在Nginx接到一个新连接通知后,调用accept()来接受尽量多的连接
worker_connections 65535;
#最大访问客户数,修改此值时,不能超过 worker_rlimit_nofile 值
}
http {
include mime.types;
default_type application/octet-stream;
#使用的默认的 MIME-type
log_format '$remote_addr - $remote_user [$time_local] "$request" '
'$status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for"';
#定义日志格式
charset UTF-8;
#设置头文件默认字符集
server_tokens off;
#Nginx打开网页报错时,关闭版本号显示
access_log off;
sendfile on;
tcp_nopush on;
#告诉nginx在一个数据包里发送所有头文件,而不一个接一个的发送
tcp_nodelay on;
#是否启用 nagle 缓存算法,告诉nginx不要缓存数据
sendfile_max_chunk 512k;
#每个进程每次调用传输数量不能大于设定的值,默认为0,即不设上限
keepalive_timeout 65;
#HTTP连接持续时间,值越大无用的线程变的越多,0:关闭此功能,默认为75
client_header_timeout 10;
client_body_timeout 10;
#以上两项是设置请求头和请求体各自的超时时间
reset_timedout_connection on;
#告诉nginx关闭不响应的客户端连接
send_timeout 30;
#客户端响应超时时间,若客户端停止读取数据,释放过期的客户端连接,默认60s
limit_conn_zone $binary_remote_addr zone=addr:5m;
#用于保存各种key,如:当前连接数的共享内存的参数,5m是5兆字节,这个值应该被设置的足够大,以存储（32K*5）32byte状态或者（16K*5）64byte状态
limit_conn addr 100;
#key最大连接数,这里key是addr,我设置的值是100,这样就允许每个IP地址最多同时打开100个连接数
server_names_hash_bucket_size 128;
#nginx启动出现could not build the server_names_hash, you should increase错误时,请提高这个参数的值一般设成64就够了
client_body_buffer_size 10K;
client_header_buffer_size 32k;
#客户端请求头部的缓冲区大小,这个可以根据你的系统分页大小进行设置
large_client_header_buffers 4 32k;
client_max_body_size 8m;
#上传文件大小设置,一般是动态应用类型
 
#线程池优化,使用--with-threads配置参数编译
#aio threads;
#thread_pool default threads=32 max_queue=65536;
#aio threads=default;
#关于更多线程请点击查看
 
#fastcgi性能调优
 
fastcgi_connect_timeout 300;
#连接到后端 Fastcgi 的超时时间
fastcgi_send_timeout 300;
#与 Fastcgi 建立连接后多久不传送数据,就会被自动断开
fastcgi_read_timeout 300;
#接收 Fastcgi 应答超时时间
fastcgi_buffers 4 64k;
#可以设置为 FastCGI 返回的大部分应答大小,这样可以处理大部分请求,较大的请求将被缓冲到磁盘
fastcgi_buffer_size 64k;
#指定读取 Fastcgi 应答第一部分需要多大的缓冲区,可以设置gastcgi_buffers选项指定的缓冲区大小
fastcgi_busy_buffers_size 128k;
#繁忙时的buffer,可以是fastcgi_buffer的两倍
fastcgi_temp_file_write_size 128k;
#在写入fastcgi_temp_path时将用多大的数据块,默认值是fastcgi_buffers的两倍,该值越小越可能报 502 BadGateway
fastcgi_intercept_errors on;
#是否传递4**&5**错误信息到客户端,或允许nginx使用error_page处理错误信息.
 
#fastcgi_cache配置优化(若是多站点虚拟主机,除fastcgi_cache_path(注意keys_zone=名称)全部加入php模块中)
 
fastcgi_cache fastcgi_cache;
#开启FastCGI缓存并指定一个名称,开启缓存可以降低CPU的负载,防止502错误出现
fastcgi_cache_valid 200 302 301 1h;
#定义哪些http头要缓存
fastcgi_cache_min_uses 1;
#URL经过多少次请求将被缓存
fastcgi_cache_use_stale error timeout invalid_header http_500;
#定义哪些情况下用过期缓存
#fastcgi_temp_path /usr/local/nginx/fastcgi_temp;
fastcgi_cache_path /usr/local/nginx/fastcgi_cache levels=1:2 keys_zone=fastcgi_cache:15m inactive=1d max_size=1g;
#keys_zone=缓存空间的名字,cache=用多少内存,inactive=默认失效时间,max_size=最多用多少硬盘空间。
#缓存目录,可以设置目录层级,举例:1:2会生成16*256个字目录
fastcgi_cache_key $scheme$request_method$host$request_uri;
#定义fastcgi_cache的key
#fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
 
#响应头
 
add_header X-Cache $upstream_cache_status;
#缓存命中
add_header X-Frame-Options SAMEORIGIN;
#是为了减少点击劫持（Clickjacking）而引入的一个响应头
add_header X-Content-Type-Options nosniff;
 
#GZIP性能优化
 
gzip on;
gzip_min_length 1100;
#对数据启用压缩的最少字节数,如:请求小于1K文件,不要压缩,压缩小数据会降低处理此请求的所有进程速度
gzip_buffers 4 16k;
gzip_proxied any;
#允许或者禁止压缩基于请求和响应的响应流,若设置为any,将会压缩所有请求
gzip_http_version 1.0;
gzip_comp_level 9;
#gzip压缩等级在0-9内,数值越大压缩率越高,CPU消耗也就越大
gzip_types text/plain text/css application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript application/json image/jpeg image/gif image/png;
#压缩类型
gzip_vary on;
#varyheader支持,让前端的缓存服务器识别压缩后的文件,代理
include /usr/local/nginx/conf/vhosts/*.conf;
#在当前文件中包含另一个文件内容的指令
 
#静态文件的缓存性能调优
 
open_file_cache max=65535 inactive=20s;
#这个将为打开文件指定缓存,max 指定缓存数量.建议和打开文件数一致.inactive 是指经过多长时间文件没被请求后删除缓存
open_file_cache_valid 30s;
#这个是指多长时间检查一次缓存的有效信息,例如我一直访问这个文件,30秒后检查是否更新,反之更新
open_file_cache_min_uses 2;
#定义了open_file_cache中指令参数不活动时间期间里最小的文件数
open_file_cache_errors on;
#NGINX可以缓存在文件访问期间发生的错误,这需要设置该值才能有效,如果启用错误缓存.则在访问资源（不查找资源）时.NGINX会报告相同的错误
 
#资源缓存优化
server {
 
#防盗链设置
 
location ~* \.(jpg|gif|png|swf|flv|wma|asf|mp3|mmf|zip|rar)$ {
#防盗类型
valid_referers none blocked *.renwole.com renwole.com;
#none blocked参数可选.允许使用资源文件的域名
if ($invalid_referer) {
return 403;
#rewrite ^/ https://renwole.com
#若不符合条件域名,则返回403或404也可以是域名
}
}
location ~ .*\.(js|css)$ {
access_log off;
expires 180d;
#健康检查或图片.JS.CSS日志.不需要记录日志.在统计PV时是按照页面计算.而且写入频繁会消耗IO.
}
location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|swf|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
access_log off;
log_not_found off;
expires 180d;
#视图&元素很少改变.可将内容缓存到用户本地.再次访问网站时就无需下载.节省流量.加快访问速度.缓存180天
}
}
server {
listen 80 default_server;
server_name .renwole.com;
rewrite ^ https://renwole.com$request_uri?;
}
server {
listen 443 ssl http2 default_server;
listen [::]:443 ssl http2;
server_name .renwole.com;
root /home/web/renwole;
index index.html index.php;
 
ssl_certificate /etc/letsencrypt/live/renwole.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/renwole.com/privkey.pem;
 
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
 
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
ssl_session_tickets off;
ssl_prefer_server_ciphers on;
add_header Strict-Transport-Security max-age=15768000;
ssl_stapling on;
ssl_stapling_verify on;
 
include /usr/local/nginx/conf/rewrite/wordpress.conf;
access_log /usr/local/nginx/logs/renwole.log;
 
location ~ \.php$ {
root /home/web/renwole;
#fastcgi_pass 127.0.0.1:9000;
fastcgi_pass unix:/var/run/www/php-cgi.sock;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
}
}
}
```

## <u>附录：依赖库</u>

```shell
git clone https://github.com/simplresty/ngx_devel_kit.git
git clone https://github.com/openresty/lua-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git
git clone https://github.com/loveshell/ngx_lua_waf.git
git clone https://github.com/openresty/lua-resty-core.git
git clone https://github.com/openresty/lua-resty-lrucache.git
git clone https://github.com/openresty/array-var-nginx-module.git
git clone https://github.com/calio/form-input-nginx-module.git
git clone https://github.com/openresty/encrypted-session-nginx-module.git
git clone https://github.com/calio/iconv-nginx-module.git
git clone https://github.com/openresty/set-misc-nginx-module.git
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/openresty/memc-nginx-module.git
git clone https://github.com/weibocom/nginx-upsync-module.git
git clone https://github.com/openresty/srcache-nginx-module.git
git clone https://github.com/openresty/redis2-nginx-module.git
git clone https://github.com/vozlt/nginx-module-vts.git
git clone https://github.com/FRiCKLE/ngx_coolkit.git
git clone https://github.com/openresty/rds-csv-nginx-module.git
git clone https://github.com/openresty/rds-json-nginx-module.git
git clone https://github.com/hamishforbes/lua-resty-consul.git
git clone https://github.com/cloudflare/lua-resty-cookie.git
git clone https://github.com/openresty/lua-resty-dns.git
git clone https://github.com/ledgetech/lua-resty-http.git
git clone https://github.com/hamishforbes/lua-resty-iputils.git
git clone https://github.com/doujiang24/lua-resty-kafka.git
git clone https://github.com/upyun/lua-resty-limit-rate.git
git clone https://github.com/openresty/lua-resty-limit-traffic.git
git clone https://github.com/openresty/lua-resty-lock.git
git clone https://github.com/cloudflare/lua-resty-logger-socket.git
git clone https://github.com/openresty/lua-resty-memcached.git
git clone https://github.com/openresty/lua-resty-mysql.git
git clone https://github.com/openresty/lua-resty-redis.git
git clone https://github.com/bungle/lua-resty-session.git
git clone https://github.com/openresty/lua-resty-string.git
git clone https://github.com/openresty/lua-resty-upload.git
git clone https://github.com/hamishforbes/lua-resty-upstream.git
git clone https://github.com/openresty/lua-resty-upstream-healthcheck.git
git clone https://github.com/openresty/lua-resty-websocket.git
```

