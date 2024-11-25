#!/bin/bash
# repository:https://github.com/lolitakon/xray_init
id=`whoami`

os_release=""
if [[ `uname -a | grep Ubuntu` != "" ]]; then
        os_release="Ubuntu"
elif [[ `uname -a | grep Debian` != "" ]]; then
        os_release="Debian"
else
        os_release="unsuitable"
fi

if [ $id != 'root' ] or [ $os_release == "unsuitable" ]; then
	echo "错误！当前用户不是root用户或所使用发行版未适配" 
else
	# 从仓库先安装部分软件
 	apt-get update
  	# debian需要额外安装和配置部分内容
 	if [ $os_release = "Debian" ]; then
 		apt-get install sudo
   		apt-get install gpg
     		
       		apt-get install ufw
       		echo "export PATH=$PATH:/usr/sbin" | tee -a /etc/profile
   		echo "alias ll='ls -l'" | tee -a /etc/profile
     		source /etc/profile
	fi
 	
 	apt-get install wget
  	apt-get install curl
	apt-get install net-tools
	apt-get install socat
	apt-get install nginx
	
	# acme.sh安装
	curl https://get.acme.sh | sh
	ln /root/.acme.sh/acme.sh /usr/local/bin/acme
	
	# geoip安装
	apt install libnginx-mod-http-geoip2
 	
 	if [ $os_release = "Debian" ]; then
		wget https://github.com/maxmind/geoipupdate/releases/download/v7.0.1/geoipupdate_7.0.1_linux_amd64.deb
  		dpkg -i geoipupdate_7.0.1_linux_amd64.deb
    		rm -rf geoipupdate_7.0.1_linux_amd64.deb
    	elif [ $os_release = "Ubuntu" ]; then
		apt install geoipupdate
	fi
 
	# warp安装
	curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
	apt-get update
	apt-get install cloudflare-warp
	
	# 3x-ui安装
	bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
	
	# Luminati安装
	read -p "是否安装Luminati?(y/n(默认))" isInstall
	if [ $isInstall = "y" ]; then 
	  wget -qO- https://brightdata.com/static/lpm/luminati-proxy-latest-setup.sh | bash
	fi
	
	# acme.sh申请证书
	mkdir /opt/tls
	systemctl stop nginx
	echo "acme.sh证书申请"
	read -p "请输入你的域名：" domainName
 	read -p "是否使用IPV6申请?(y/n（默认）)："  isIpv6
	acme --set-default-ca --server letsencrypt
 	
  	if [ $isIpv6 = "y" ]; then 
	  acme  --issue -d $domainName --standalone -k ec-256 --listen-v6
	else
	  acme  --issue -d $domainName --standalone -k ec-256
 	fi
  	
	acme --installcert -d $domainName --ecc  --key-file   /opt/tls/server.key   --fullchain-file /opt/tls/server.crt 
	
	# 防火墙放行
	ufw allow 443
 	ufw allow 80
	echo "请等待脚本完成后自行放行ssh并ufw enable"
 	sleep 1s
	
	# warp初始化
	warp-cli mode proxy
	warp-cli proxy port 40000
	warp-cli registration new
	warp-cli connect
	# 查询warp对应ip
	curl ifconfig.me --proxy socks5://127.0.0.1:40000

	# 备份默认配置文件并清空原文件（可选）
 	read -p "是否备份配置文件并清空?(y/n(默认))" isModConfig
 	if [ $isModConfig = "y" ]; then
  	  cd /etc/
	  cp GeoIP.conf GeoIP.conf.default
   	  echo "" > GeoIP.conf
   	  cd nginx
      	  cp nginx.conf nginx.conf.default
	  echo "" > nginx.conf
	fi
 	
 	# 修改时区
  	timedatectl set-timezone Asia/Shanghai
   	reboot
	
	echo "luminati请自行开放防火墙与配置"
	echo "基础初始化完毕，请自行初始化3x-ui（命令x-ui）,修改/etc/nginx/nginx.conf配置文件"
	echo "warp可能无法使用脚本注册，如果netstat 40000端口没反应请手动注册"
	echo "可参考https://raw.githubusercontent.com/lolitakon/study/main/Linux/%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91%E7%9B%B8%E5%85%B3/nginx%E4%BC%AA%E8%A3%85%E6%A8%A1%E6%9D%BF"
fi
