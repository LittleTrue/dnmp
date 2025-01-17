#!/bin/bash
# -*- coding: UTF-8 -*-
# 获取当前脚本执行路径
SELFPATH=$(cd "$(dirname "$0")"; pwd)
GOOS=`go env | grep GOOS | awk -F\" '{print $2}'`
GOARCH=`go env | grep GOARCH | awk -F\" '{print $2}'`

if [ ! DOMAIN];then
    echo '请输入一个域名（映射到本服务器的代理根域名）：'
    read DOMAIN
fi

if [ ! port];then
    echo '请输入服务端启动代理的端口(本服务器对外的代理端口, 不输入会随机生成)：'
    read port
fi

install_yilai(){
    yum -y install zlib-devel openssl-devel perl hg cpio expat-devel gettext-devel curl curl-devel perl-ExtUtils-MakeMaker hg wget gcc gcc-c++ unzip
}

# 安装git
install_git(){
    unstall_git
    if [ ! -f $SELFPATH/git-2.9.3.tar.gz ];then
        wget https://www.kernel.org/pub/software/scm/git/git-2.9.3.tar.gz
    fi
    tar zxvf git-2.9.3.tar.gz
    cd git-2.9.3
    ./configure --prefix=/usr/local/git
    make
    make install
    ln -s /usr/local/git/bin/* /usr/bin/
    rm -rf $SELFPATH/git-2.9.3
}

# 卸载git
unstall_git(){
    rm -rf /usr/local/git
    rm -rf /usr/local/git/bin/git
    rm -rf /usr/local/git/bin/git-cvsserver
    rm -rf /usr/local/git/bin/gitk
    rm -rf /usr/local/git/bin/git-receive-pack
    rm -rf /usr/local/git/bin/git-shell
    rm -rf /usr/local/git/bin/git-upload-archive
    rm -rf /usr/local/git/bin/git-upload-pack
}


# 安装go
install_go(){
    cd $SELFPATH
    uninstall_go
    # 动态链接库，用于下面的判断条件生效
    ldconfig
    # 判断操作系统位数下载不同的安装包
    if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ];then
        # 判断文件是否已经存在
        if [ ! -f $SELFPATH/go1.4.2.linux-amd64.tar.gz ];then
            wget https://studygolang.com/dl/golang/go1.4.2.linux-amd64.tar.gz
        fi
        tar zxvf go1.4.2.linux-amd64.tar.gz
    else
        if [ ! -f $SELFPATH/go1.4.2.linux-386.tar.gz ];then
            wget https://studygolang.com/dl/golang/go1.4.2.linux-386.tar.gz
        fi
        tar zxvf go1.4.2.linux-386.tar.gz
    fi
    mv go /usr/local/
    ln -s /usr/local/go/bin/* /usr/bin/
}

# 卸载go

uninstall_go(){
    rm -rf /usr/local/go
    rm -rf /usr/bin/go
    rm -rf /usr/bin/godoc
    rm -rf /usr/bin/gofmt
}

# 安装ngrok
install_ngrok(){
    uninstall_ngrok
    cd /usr/local
    if [ ! -f /usr/local/ngrok.zip ];then
        cd /usr/local/
        wget http://www.sunnyos.com/ngrok.zip
    fi
    unzip ngrok.zip
    export GOPATH=/usr/local/ngrok/
    export NGROK_DOMAIN=$DOMAIN
    cd ngrok
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
    openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000
    cp rootCA.pem assets/client/tls/ngrokroot.crt
    cp server.crt assets/server/tls/snakeoil.crt
    cp server.key assets/server/tls/snakeoil.key
    # 替换下载源地址
    sed -i 's#code.google.com/p/log4go#github.com/keepeye/log4go#' /usr/local/ngrok/src/ngrok/log/logger.go
    cd /usr/local/go/src
    GOOS=$GOOS GOARCH=$GOARCH ./make.bash
    cd /usr/local/ngrok
    GOOS=$GOOS GOARCH=$GOARCH make release-server
    /usr/local/ngrok/bin/ngrokd -domain=$NGROK_DOMAIN -httpAddr=":80" -httpsAddr=":443"
}

# 卸载ngrok
uninstall_ngrok(){
    rm -rf /usr/local/ngrok
}

# 编译客户端
compile_client(){
    cd /usr/local/go/src
    GOOS=$1 GOARCH=$2 ./make.bash
    cd /usr/local/ngrok/
    GOOS=$1 GOARCH=$2 make release-client
}

# 生成客户端
client(){
    echo "1、Linux 32位"
    echo "2、Linux 64位"
    echo "3、Windows 32位"
    echo "4、Windows 64位"
    echo "5、Mac OS 32位"
    echo "6、Mac OS 64位"
    echo "7、Linux ARM"

    read num
    case "$num" in
        [1] )
            compile_client linux 386
        ;;
        [2] )
            compile_client linux amd64
        ;;
        [3] )
            compile_client windows 386
        ;;
        [4] ) 
            compile_client windows amd64
        ;;
        [5] ) 
            compile_client darwin 386
        ;;
        [6] ) 
            compile_client darwin amd64
        ;;
        [7] ) 
            compile_client linux arm
        ;;
        *) echo "选择错误，退出";;
    esac

}


echo "-- 请输入下面数字进行选择: "
echo "------------------------------------------------------------"
echo "----- 温馨提示: power by gxz  -------------------------------"
echo "----- 注意云盾或者服务器firewall或ip table的端口拦截 ----------"
echo "----- 客户端脚本与服务端连接的4443和服务端代理端口均需开放  ----"
echo "------------------------------------------------------------"
echo "1、全新安装, 安装后查看输出, 哪项失败重新安装即可"
echo "2、安装依赖"
echo "3、安装git(如果404请更换wget源url)"
echo "4、安装go环境(如果404请更换wget源url)"
echo "5、安装ngrok(如果404请更换wget源url)"
echo "6、生成客户端"
echo "7、全部安装内容卸载"
echo "8、启动服务(单次调试启动, 退出ssh失效)"
echo "9、查看配置文件"
echo "0、启动服务(服务线程模式启动, 重启失效)"
echo "------------------------------------------------------------"
read num
case "$num" in
    [1] )
        install_yilai
        install_git
        install_go
        install_ngrok
    ;;
    [2] )
        install_yilai
    ;;
    [3] )
        install_git
    ;;
    [4] )
        install_go
    ;;
    [5] )
        install_ngrok
    ;;
    [6] )
        client
    ;;
    [7] )
        unstall_git
        uninstall_go
        uninstall_ngrok
    ;;
    [8] )
        echo "调试启动中"
        /usr/local/ngrok/bin/ngrokd -domain=$DOMAIN -httpAddr=":$port" -httpsAddr=":$https_port"
    ;;
    [9] )
        echo "#############################################"
        echo "#创建ngrok.cfg文件并添加以下内容, 放于客户端目录。"
        echo server_addr: '"'$DOMAIN:4443'"'
        echo "trust_host_root_certs: false"
        echo "#############################################"
        echo "不同环境建议创建运行脚本, 比如windos将windos环境启动命令配置为bat授权运行!!!"
        echo "#############################################"
        echo "#Window启动脚本"
        echo "示例: ngrok -config=ngrok.cfg -subdomain=winpc 80"
        echo "ngrok -config=ngrok.cfg -subdomain=基于代理根域名单个客户端的单独域名前缀 客户端本地映射的端口号"
        echo "#############################################"
        echo "#Linux Mac 启动脚本"
        echo "./ngrok -config=./ngrok.cfg -subdomain=基于代理根域名单个客户端的单独域名前缀  客户端本地映射的端口号"
        echo "#############################################"
        echo "#Linux Mac 后台启动脚本"
        echo "setsid ./ngrok -config=./ngrok.cfg -subdomain=基于代理根域名单个客户端的单独域名前缀 客户端本地映射的端口号"
        echo "#############################################"
    ;;
    [0] )
        echo "服务线程常驻启动, 启动后关闭请使用kill -9 命令"
        nohup /usr/local/ngrok/bin/ngrokd -domain=$DOMAIN -httpAddr=":$port" -httpsAddr=":$https_port"
    ;;
    *) echo "选项错误!!";;
esac