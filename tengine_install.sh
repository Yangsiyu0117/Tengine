#!/bin/bash
# date : 2022.11.22
# Use：Centos 7 or openeluer
# Install Tengine-Nginx

#骚气颜色
show_str_Black()
{
        echo -e "\033[30m $1 \033[0m"
}
show_str_Red()
{
        echo -e "\033[31m $1 \033[0m"
}
show_str_Green()
{
        echo -e "\033[32m $1 \033[0m"
}
show_str_Yellow()
{
        echo -e "\033[33m $1 \033[0m"
}
show_str_Blue()
{
        echo -e "\033[34m $1 \033[0m"
}
show_str_Purple()
{
        echo -e "\033[35m $1 \033[0m"
}
show_str_SkyBlue()
{
        echo -e "\033[36m $1 \033[0m"
}
show_str_White()
{
        echo -e "\033[37m $1 \033[0m"
}


#获取当前时间
DATE=`date +"%Y-%m-%d %H:%M:%S"`
#获取当前主机名
HOSTNAME=`hostname -s`
#获取当前用户
USER=`whoami`
#获取当前内核版本参数
KERNEL=`uname -r | cut -f 1-3 -d.`


if [ -f "/etc/redhat-release" ];then
        #获取当前系统版本
        SYSTEM=`cat /etc/redhat-release`
        os=centos
elif [ -f "/etc/openEuler-release" ];then
        SYSTEM=`cat /etc/openEuler-release`
        os=openeuler
else
       show_str_Red "脚本不适配当前系统，请选择退出。谢谢！"
       exit 0
fi

log_file="logfile_`date +"%Y-%m-%d-%H%M%S"`.log"


###
### Install Tengine+Lua
###
### Usage:
###   bash install.sh -h
###   logfile in /root/logfile_`date +"%Y-%m-%d-%H%M%S"`.log
###          日志文件可以帮助你快速排错
###   tengine_install.tar.gz
###      -----install.sh
###             运行脚本
###      -----nginx.conf
###             nginx配置文件
###      -----offline_nginx.tar.gz
###             离线安装包，包括：gcc\gcc-c++\pcre\zlib\openssl(centos and openeuler)
###      -----tengine-2.3.3.tar.gz
###              tengine安装包
###      -----v2.1-20220915.tar.gz
###              luajit安装包
###          
### Options:
###  h  -h --help    Show this message.

help() {
    sed -rn 's/^### ?//;T;p' "$0"
}

if  [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "h" ]]; then
    help
    exit 1
fi


#检测网络链接畅通
function network()
{
    #超时时间
    local timeout=1

    #目标网站
    local target=www.baidu.com

    #获取响应状态码
    local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`

    if [ "x$ret_code" = "x200" ]; then
        #网络畅通
        return 1
    else
        #网络不畅通
        return 0
    fi

    return 0
}


nginx_info(){
        log_correct "输出nginx相关信息"
        show_str_Green "安装目录：/etc/nginx/"
        show_str_Yellow "日志目录：/var/log/nginx/"
        show_str_Purple "配置文件目录：/etc/nginx/conf/"
}

source_profile()
{
    echo 'export PS1="\[\033[01;31m\]\u\[\033[00m\]@\033[01;32m\]\H\[\033[00m\][\[\033[01;33m\]\t\[\033[00m\]]:\[\033[01;34m\]\W\[\033[00m\]\n$"' >> /etc/profile
    source /etc/profile
}

# log_correct函数打印正常的输出到日志文件
function log_correct () {
DATE=`date "+%Y-%m-%d %H:%M:%S"`
USER=$(whoami) ####那个用户在操作
show_str_Green "${DATE} ${USER} $0 [INFO] $@" >> /root/$log_file
}


# log_error函数打印错误的输出到日志文件
function log_error ()
{
DATE=`date "+%Y-%m-%d %H:%M:%S"`
USER=$(whoami)
show_str_Red "${DATE} ${USER} $0 [ERROR] $@" >> /root/$log_file
}


# function CHECK_STATUS(){
#     if [ $? == 0 ];then
#         tput rc && tput ed
#         printf "\033[1;36m%-7s\033[0m\n" 'SUCCESS'
#     else
#         tput rc && tput ed
#         printf "\033[1;31m%-7s\033[0m\n" 'FAILED'
#     fi
# }


software_install(){
        show_str_Blue "========================================"
        show_str_Blue "            正在安装依赖中。。。"
        show_str_Blue "========================================"
        log_correct "####################################################################################安装依赖###################################################"
        yum install gcc gcc-c++  pcre pcre-devel  zlib zlib-devel  openssl openssl-devel wget -y >>/root/$log_file 2>&1
}

luajit_install(){
        show_str_Blue "========================================"
        show_str_Blue "            安装并编译luajit模块。。。"
        show_str_Blue "========================================"
        #wget -c https://github.com/openresty/luajit2/archive/refs/tags/v2.1-20220915.tar.gz >>/root/$log_file 2>&1
        cd /root/
        tar -xf v2.1-20220915.tar.gz
        cd luajit2-2.1-20220915
        log_correct "###################################################编译luajit模块###################################################"
        make install PREFIX=/usr/local/luajit >>/root/$log_file 2>&1
cat  >> /etc/profile <<hh
export LUAJIT_LIB=/usr/local/luajit/lib
export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
hh
        source /etc/profile
        cd /root/
}

tar_nginx(){
        #wget -c http://tengine.taobao.org/download/tengine-2.3.3.tar.gz >>/root/$log_file 2>&1
        cd /root/
        tar -xf tengine-2.3.3.tar.gz
        cd /root/tengine-2.3.3
}

online_make_nginx(){
        show_str_Blue "========================================"
        show_str_Blue "    编译安装中。。。（时间会较长，请稍等）"
        show_str_Blue "========================================"
        log_correct "###################################################nginx ./configure编译###################################################"
        ./configure --prefix=/etc/nginx --conf-path=/etc/nginx/conf/nginx.conf  --with-pcre  --with-debug  --with-http_stub_status_module  --with-http_ssl_module --add-module=modules/ngx_http_lua_module --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=modules/ngx_http_upstream_check_module  --add-module=modules/ngx_http_reqstat_module >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
         log_correct "###################################################nginx make###################################################"
         make >> /root/$log_file 2>&1
         log_correct "###################################################nginx make install###################################################"
         make install >> /root/$log_file 2>&1
        else
         log_error "编译失败，请联系管理员"
         show_str_Red "========================================"
         show_str_Red "          编译失败，请联系管理员!!!"
         show_str_Red "========================================"
         exit 0
        fi
}

offline_make_nginx(){
        show_str_Blue "========================================"
        show_str_Blue "    编译安装中。。。（时间会较长，请稍等）"
        show_str_Blue "========================================"
        log_correct "###################################################nginx ./configure编译###################################################"
        ./configure --prefix=/etc/nginx --conf-path=/etc/nginx/conf/nginx.conf  --with-pcre=/usr/local/offline_nginx/$os/pcre/pcre-8.32 --with-zlib=/usr/local/offline_nginx/$os/zlib/zlib-1.2.13 --with-openssl=/usr/local/offline_nginx/$os/openssl/openssl-1.0.2k  --with-debug  --with-http_stub_status_module  --with-http_ssl_module --add-module=modules/ngx_http_lua_module --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=modules/ngx_http_upstream_check_module  --add-module=modules/ngx_http_reqstat_module >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
         log_correct "###################################################nginx make###################################################"
         make >> /root/$log_file 2>&1
         log_correct "###################################################nginx make install###################################################"
         make install >> /root/$log_file 2>&1
        else
         log_error "编译失败，请联系管理员"
         show_str_Red "========================================"
         show_str_Red "          编译失败，请联系管理员!!!"
         show_str_Red "========================================"
         exit 0
        fi
}


firewalld_config(){
        systemctl status firewalld | grep "running"  >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                log_correct "###################################################创建防火钱规则，添加80端口###################################################"
                firewall-cmd --zone=public --add-port=80/tcp --permanent >> /root/$log_file 2>&1
                firewall-cmd --reload >> /root/$log_file 2>&1
        else

                log_correct "##################################################firewalld 目前是关闭的状态##################################################"
        fi
}

nginx_status(){
        status=`systemctl status nginx | grep running | wc -l`
        if [ $status -eq '1' ];then
                show_str_Blue "========================================"
                show_str_Blue "             Nginx启动成功"
                show_str_Blue "========================================"
        else
                show_str_Red "----------------------------------"
                show_str_Red "|            警告！！！            |"
                show_str_Red "|    Nginx 启动失败，请联系管理员！|"
                show_str_Red "----------------------------------"
                exit 0
        fi
}

start_nginx(){
        log_correct "添加nginx启动文件"
cat << EOF >/lib/systemd/system/nginx.service
[Unit]


Description=The nginx HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/etc/nginx/sbin/nginx -t
ExecStart=/etc/nginx/sbin/nginx -c /etc/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
        chmod 745 /lib/systemd/system/nginx.service
        systemctl daemon-reload
}

online_install(){ 
        software_install
        luajit_install
        tar_nginx
        online_make_nginx
        nginx_conf
        start_nginx
        log_correct "为nginx设置开启自启"
        systemctl enable nginx.service >> /root/$log_file 2>&1
        log_correct "启动nginx"
        systemctl start nginx.service
        nginx_status

}

uninstall_nginx(){
        log_correct "remove nginx directory"
        uninstall_date=`date +"%Y-%m-%d-%H%M%S"`
        trash=/tmp/trash/$uninstall_date
        mkdir -p $trash
        show_str_Purple "取消nginx开启自启"
        systemctl disable nginx.service &>/dev/null
        show_str_Purple "停止nginx服务"
        systemctl stop nginx.service &>/dev/null
        if [ -f '/lib/systemd/system/nginx.service' ];then
                mv /lib/systemd/system/nginx.service $trash
        fi
        show_str_Purple "将nginx相关目录移至/tmp/trash下"
        if [ -d '/root/luajit2-2.1-20220915' ] || [ -d '/root/tengine-2.3.3' ] || [ -d '/etc/nginx' ] || [ -d '/usr/local/offline_nginx' ];then
                mv /root/luajit2-2.1-20220915 $trash &>/dev/null
                mv /root/tengine-2.3.3 $trash &>/dev/null
                mv /etc/nginx $trash &>/dev/null
                mv /usr/local/offline_nginx $trash &>/dev/null
        fi
        systemctl daemon-reload
        sed -i '/LUAJIT_LIB/d' /etc/profile
        sed -i '/LUAJIT_INC/d' /etc/profile
        source /etc/profile
        show_str_Green "nginx已全部移除"
}



check_nginx(){
        if [ -d "/etc/nginx" ];then
                # echo -e "\033[31;1m nginx directory already exists！ \033[0m"
                show_str_Red "--------------------------------------------"
                show_str_Red "|                  警告！！！              |"
                show_str_Red "|    nginx directory already exists！      |"
                show_str_Red "--------------------------------------------"
                log_error "nginx directory already exists"
        elif [ `ps -ef|grep nginx|grep -v grep|wc -l` -ne '0' ];
                then
                # echo -e "\033[31;1m nginx has running already exists! please check! \033[0m"
                show_str_Red "-------------------------------------------------------------"
                show_str_Red "|                        警告！！！                         |"
                show_str_Red "|    nginx has running already exists! please check!        |"
                show_str_Red "-------------------------------------------------------------"
                log_error "nginx has running already exists! please check!"
        else
                # show_str_Green "检测当前服务器未安装Tengine-Nginx"
                show_str_Green "-------------------------------------------"
                show_str_Green "|                提醒！！！                |"
                show_str_Green "|    检测当前服务器未安装Tengine-Nginx     |"
                show_str_Green "-------------------------------------------"
                log_correct "检测当前服务器未安装Tengine-Nginx"
        fi
}

nginx_conf(){
        ip="`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"| head -n 1 |cut -d . -f 1-3`.0"
        mv /etc/nginx/conf/nginx.conf /etc/nginx/conf/nginx.conf_bak
        cp -r /root/nginx.conf /etc/nginx/conf/nginx.conf
        sed -i '93s/allow/allow '$ip'\/32;/g' /etc/nginx/conf/nginx.conf
        sed -i '100s/allow/allow '$ip'\/32;/g' /etc/nginx/conf/nginx.conf
        sed -i '107s/allow/allow '$ip'\/32;/g' /etc/nginx/conf/nginx.conf
        mkdir -p /var/log/nginx/
}


centos7_offline_install(){
        offline_directory_centos=/usr/local/offline_nginx/centos
        tar -xf /root/offline_nginx.tar.gz -C /usr/local/ >> /root/$log_file 2>&1
        # 安装gcc
        show_str_Yellow "========================================"
        show_str_Yellow "               安装gcc。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_centos/gcc && rpm -Uvh *.rpm --nodeps --force
        log_correct "##################################################gcc 安装成功##################################################"
        # 安装gcc-c++
        show_str_Yellow "========================================"
        show_str_Yellow "               安装gcc-c++。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_centos/gcc-c++ && rpm -Uvh *.rpm --nodeps --force
        log_correct "##################################################gcc-c++ 安装成功##################################################"
        # 安装pcre
        show_str_Yellow "========================================"
        show_str_Yellow "               安装pcre。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_centos/pcre && tar -xf pcre-8.32.tar.gz
        cd $offline_directory_centos/pcre/pcre-8.32
        log_correct "##################################################Pcre ./configure##################################################"
        ./configure >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Pcre Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          pcre ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          pcre ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        # 安装zlib
        show_str_Yellow "========================================"
        show_str_Yellow "               安装zlib。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_centos/zlib && tar -xf zlib-1.2.13.tar.gz
        cd $offline_directory_centos/zlib/zlib-1.2.13
        ./configure >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Zlib Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          zlib ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          zlib ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        # 安装openssl
        show_str_Yellow "========================================"
        show_str_Yellow "               安装openssl。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_centos/openssl && tar -xf openssl-1.0.2k.tar.gz
        cd $offline_directory_centos/openssl/openssl-1.0.2k
        ./config >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Openssl Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          openssl ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          openssl ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        log_correct "========================================"
        log_correct "          离线依赖包已经全部安装完毕"
        log_correct "========================================"
        luajit_install
        tar_nginx
        offline_make_nginx
        nginx_conf
        start_nginx
        log_correct "为nginx设置开启自启"
        systemctl enable nginx.service >> /root/$log_file 2>&1
        log_correct "启动nginx"
        systemctl start nginx.service


}

openeuler_offline_install(){
        offline_directory_openeuler=/usr/local/offline_nginx/openeuler
        tar -xf /root/offline_nginx.tar.gz -C /usr/local/ >> /root/$log_file 2>&1
        # 安装gcc
        show_str_Yellow "========================================"
        show_str_Yellow "               安装gcc。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_openeuler/gcc && rpm -Uvh *.rpm --nodeps --force
        log_correct "##################################################gcc 安装成功##################################################"
        # 安装gcc-c++
        show_str_Yellow "========================================"
        show_str_Yellow "               安装gcc-c++。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_openeuler/gcc-c++ && rpm -Uvh *.rpm --nodeps --force
        log_correct "##################################################gcc-c++ 安装成功##################################################"
        # 安装pcre
        show_str_Yellow "========================================"
        show_str_Yellow "               安装pcre。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_openeuler/pcre && tar -xf pcre-8.32.tar.gz
        cd $offline_directory_openeuler/pcre/pcre-8.32
        log_correct "##################################################Pcre ./configure##################################################"
        ./configure >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Pcre Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          pcre ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          pcre ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        # 安装zlib
        show_str_Yellow "========================================"
        show_str_Yellow "               安装zlib。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_openeuler/zlib && tar -xf zlib-1.2.13.tar.gz
        cd $offline_directory_openeuler/zlib/zlib-1.2.13
        ./configure >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Zlib Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          zlib ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          zlib ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        # 安装openssl
        show_str_Yellow "========================================"
        show_str_Yellow "               安装openssl。。。"
        show_str_Yellow "========================================"
        cd $offline_directory_openeuler/openssl && tar -xf openssl-1.0.2k.tar.gz
        cd $offline_directory_openeuler/openssl/openssl-1.0.2k
        ./config >> /root/$log_file 2>&1
        if [ `echo $?` -eq 0 ];then
                make >> /root/$log_file 2>&1
                make install >> /root/$log_file 2>&1
                log_correct "##################################################Openssl Make && Make install##################################################"
        else
                show_str_Red "========================================"
                show_str_Red "          openssl ./configure失败。。。"
                show_str_Red "========================================"
                log_error "========================================"
                log_error "          openssl ./configure失败。。。"
                log_error "========================================"
                exit 0
        fi
        log_correct "========================================"
        log_correct "          离线依赖包已经全部安装完毕"
        log_correct "========================================"
        luajit_install
        tar_nginx
        offline_make_nginx
        nginx_conf
        start_nginx
        log_correct "为nginx设置开启自启"
        systemctl enable nginx.service >> /root/$log_file 2>&1
        log_correct "启动nginx"
        systemctl start nginx.service

}

function printinput(){
echo "========================================"
cat << EOF
|-------------系-统-信-息--------------
|  时间            :$DATE                                        
|  主机名称        :$HOSTNAME
|  当前用户        :$USER                                        
|  内核版本        :$KERNEL
|  系统版本        :$SYSTEM  
----------------------------------------
----------------------------------------
|****请选择你要操作的项目:[0-3]****|
----------------------------------------
(1) 检查当前环境
(2) 安装Tengine-Nginx
(3) 卸载Tengine-Nginx
(4) 离线安装Tengine-Nginx
(0) 退出
EOF

read -p "请选择[0-4]: " input
case $input in
1)
check_nginx
network
if [ $? -eq 0 ];then
        show_str_Red "-------------------------------------------"
        show_str_Red "|                提醒！！！                |"
        show_str_Red "|    当前服务器无网络，请选择离线安装！！！     |"
        show_str_Red "-------------------------------------------"
        printinput
fi
        show_str_Green "-------------------------------------------"
        show_str_Green "|                提醒！！！                |"
        show_str_Green "|           当前服务器网络正常！！！       |"
        show_str_Green "-------------------------------------------"
printinput
;;
2)
firewalld_config
online_install
nginx_info
printinput
;;
3)
uninstall_nginx
printinput
;;
4)
if [ $os == 'centos' ];then
        os=centos
        centos7_offline_install
        nginx_info
fi
if [[ $os == 'openeuler' ]]; then
        os=openeuler
        openeuler_offline_install
        nginx_info
fi
printinput
;;
0)
log_correct "exit"
clear
exit 0
;;
*)
show_str_Red "----------------------------------"
show_str_Red "|            警告！！！            |"
show_str_Red "|    请 输 入 正 确 的 选 项       |"
show_str_Red "----------------------------------"
 for i in `seq -w 3 -1 1`
   do
     echo -ne "\b\b$i";
     sleep 1;
   done
 printinput
;;
esac
}

printinput