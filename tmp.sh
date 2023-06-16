#!/bin/bash
#本脚本安装软件如下:1.acme.sh以及所需依赖socat 2.nginx 3.warp
#无任何商业性质，原则上不允许转载，转载需询问我本人！
id=`whoami`
if [ $id != 'root' ]; then
	echo "error!current user is not root！！" 
	echo "错误！当前用户不是root用户！！" 
fi

#从仓库先安装部分软件
apt-get update
apt-get install net-tools
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

#防火墙放行
ufw allow 10086
ufw allow 443


#warp初始化
warp-cli register
warp-cli set-mode proxy
warp-cli set-proxy-port 40000
warp-cli connect
#查询warp对应ip
curl ifconfig.me --proxy socks5://127.0.0.1:40000

