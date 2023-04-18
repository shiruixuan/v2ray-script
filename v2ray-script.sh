#!/bin/bash
# v2ray一键安装脚本
# Author: shiruixuan<https://github.com/shiruixuan>


mkdir -p ~/nginx/conf.d
mkdir -p ~/v2ray

docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --set-default-ca --server letsencrypt
docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --issue -d bjjtw.top --keylength ec-256 --standalone
docker run --rm -it -v ~/acme.sh:/acme.sh -v ~/nginx/sslcert:/etc/nginx/sslcert --net=host neilpang/acme.sh --install-cert -d bjjtw.top --ecc --key-file /etc/nginx/sslcert/bjjtw.top.key --fullchain-file /etc/nginx/sslcert/bjjtw.top.pem

echo "0 0 * * * docker run --rm -it --net=host -v ~/acme.sh:/acme.sh -v ~/nginx/sslcert:/etc/nginx/sslcert neilpang/acme.sh --cron > /dev/null" >> /var/spool/cron/crontabs/root

wget https://raw.githubusercontent.com/shiruixuan/v2ray-script/main/nginx.conf -O ~/nginx/nginx.conf
wget https://raw.githubusercontent.com/shiruixuan/v2ray-script/main/bjjtw.top.conf -O ~/nginx/conf.d/bjjtw.top.conf
docker run -d --net=host --name=nginx --restart=always -v ~/nginx/nginx.conf:/etc/nginx/nginx.conf -v ~/nginx/conf.d:/etc/nginx/conf.d -v ~/nginx/sslcert:/etc/nginx/sslcert nginx

bash <(curl -fsSL git.io/warp.sh) proxy

wget https://raw.githubusercontent.com/shiruixuan/config/main/config.json -O ~/v2ray/config.json
docker run -d --net=host --name=v2ray --restart=always -v ~/v2ray/config.json:/etc/v2ray/config.json v2fly/v2fly-core:v4.45.2
