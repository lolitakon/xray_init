#!/bin/bash
#该shell是本人为了方便快速搭建科学上网工具制作
#本脚本安装软件如下:1.acme.sh以及所需依赖socat 2.nginx 3.warp
#无任何商业性质，原则上不允许转载，转载需询问我本人！
id=`whoami`
if [ $id != 'root' ]; then
	echo "error!current user is not root！！" 
	echo "错误！当前用户不是root用户！！" 
fi

#从仓库先安装部分软件
apt-get update
apt-get install socat
apt-get install nginx

#acme.sh安装
curl https://get.acme.sh | sh
ln /root/.acme.sh/acme.sh /usr/local/bin/acme

#warp安装
curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
apt-get update
apt-get install cloudflare-warp

#acme.sh申请证书
mkdir /opt/tls
systemctl stop nginx
read -p "请输入你的域名" domainName
acme --set-default-ca --server letsencrypt
acme  --issue -d $domainName --standalone -k ec-256
acme --installcert -d $domainName --ecc  --key-file   /opt/tls/server.key   --fullchain-file /opt/tls/server.crt 

#warp初始化
warp-cli register
warp-cli set-mode proxy
warp-cli set-proxy-port 40000
warp-cli connect
#查询warp对应ip
curl ifconfig.me --proxy socks5://127.0.0.1:40000

echo "基础初始化完毕，请自行安装x-ui,修改/etc/nginx/nginx.conf配置文件"
echo "warp可能无法使用脚本注册，如果netstat 40000端口没反应请手动注册"
echo "x-ui安装:bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)"
echo "可参考https://raw.githubusercontent.com/lolitakon/study/main/Linux/%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91%E7%9B%B8%E5%85%B3/nginx%E4%BC%AA%E8%A3%85%E6%A8%A1%E6%9D%BF"


