#!/bin/bash
# v2ray一键安装脚本
# Author: shiruixuan<https://github.com/shiruixuan>


if [ $1 ]; then
    DOMAIN=$1
else
    while true
    do
        read -p " 请输入伪装域名：" DOMAIN_INPUT
        if [[ -z "$DOMAIN_INPUT" ]]; then
            echo " 域名输入错误，请重新输入！"
        else
            break
        fi
    done
    DOMAIN=$DOMAIN_INPUT
fi
echo " 伪装域名(host)：$DOMAIN"

apt install -y docker.io

mkdir -p ~/nginx/conf.d
mkdir -p ~/nginx/cert
mkdir -p ~/v2ray

if [ ! -s ~/nginx/cert/$DOMAIN.key ] || [ ! -s ~/nginx/cert/$DOMAIN.pem ]; then
	docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --set-default-ca --server letsencrypt
	docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --issue -d $DOMAIN --keylength ec-256 --standalone
	docker run --rm -it -v ~/acme.sh:/acme.sh -v ~/nginx/cert:/etc/nginx/cert --net=host neilpang/acme.sh --install-cert -d $DOMAIN --ecc --key-file /etc/nginx/cert/$DOMAIN.key --fullchain-file /etc/nginx/cert/$DOMAIN.pem
	echo "0 0 * * * docker run --rm -it --net=host -v ~/acme.sh:/acme.sh -v ~/nginx/cert:/etc/nginx/cert neilpang/acme.sh --cron > /dev/null" >> /var/spool/cron/crontabs/root
fi

cat > ~/nginx/nginx.conf<<-EOF
user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    server_tokens off;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    gzip                on;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > ~/nginx/conf.d/$DOMAIN.conf<<-EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$server_name:443\$request_uri;
}

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name $DOMAIN;
    charset utf-8;

    # ssl配置
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_ecdh_curve secp384r1;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_certificate /etc/nginx/cert/$DOMAIN.pem;
    ssl_certificate_key /etc/nginx/cert/$DOMAIN.key;

    root /usr/share/nginx/html;
    location / {
        proxy_ssl_server_name on;
        proxy_pass https://86817.com/;
        proxy_set_header Accept-Encoding '';
        sub_filter "86817.com" "$DOMAIN";
        sub_filter_once off;
    }
    

    location /cULsKRN {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:29535;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

docker run -d --net=host --name=nginx --restart=always -v ~/nginx/nginx.conf:/etc/nginx/nginx.conf -v ~/nginx/conf.d:/etc/nginx/conf.d -v ~/nginx/cert:/etc/nginx/cert nginx

bash <(curl -fsSL https://raw.githubusercontent.com/P3TERX/warp.sh/main/warp.sh) proxy
cat > ~/v2ray/config.json<<-EOF
{
    "stats": {},
    "log": {
        "access": "/var/log/v2ray/access.log",
        "error": "/var/log/v2ray/error.log",
        "loglevel": "warning"
    },
    "api": {
        "tag": "api",
        "services": [
            "HandlerService",
            "LoggerService",
            "StatsService"
        ]
    },
    "policy": {
        "levels": {
            "0": {
                "statsUserUplink": true,
                "statsUserDownlink": true
            },
            "1": {
                "statsUserUplink": true,
                "statsUserDownlink": true
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true
        }
    },
    "inbounds": [
        {
            "port": 29535,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "email": "user1@mail.com",
                        "id": "a1521187-6faa-412d-861d-cccf29c6217f",
                        "level": 1,
                        "alterId": 0
                    },
                    {
                        "email": "user2@mail.com",
                        "id": "a1521187-6faa-412d-861d-cccf29c6218f",
                        "level": 1,
                        "alterId": 0
                    },
                    {
                        "email": "user3@mail.com",
                        "id": "a1521187-6faa-412d-861d-cccf29c6215f",
                        "level": 1,
                        "alterId": 0
                    },
                    {
                        "email": "user4@mail.com",
                        "id": "a1521187-6faa-412d-861d-cccf29c6216f",
                        "level": 1,
                        "alterId": 0
                    }
                ],
                "disableInsecureEncryption": false
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/cULsKRN",
                    "header": {
                        "Host": "$DOMAIN"
                    }
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {
            "listen": "127.0.0.1",
            "port": 10085,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            },
            "tag": "api"
        }
        //include_ss
        //include_socks
        //include_mtproto
        //include_in_config
        //
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        },
        {
            "tag":"warp",
            "protocol": "socks",
            "settings": {
                "servers": [
                    {
                        "address": "127.0.0.1",
                        "port": 40000
                    }
                ]
            }
        }
        //include_out_config
        //
    ],
    "dns": {
        "servers": [
            "https+local://dns.google/dns-query",
            "8.8.8.8",
            "1.1.1.1",
            "localhost"
        ]
    },
    "routing": {
        "settings": {
            "rules": [
                {
                    "inboundTag": [
                        "api"
                    ],
                    "outboundTag": "api",
                    "type": "field"
                },
                {
                    "outboundTag": "warp",
                    "type": "field",
                    "domain":[
                        "domain:openai.com",
                        "domain:ai.com"
                    ]
                }
                //include_ban_ad
                //include_rules
                //
            ]
        },
        "strategy": "rules"
    },
    "transport": {
        "kcpSettings": {
            "uplinkCapacity": 100,
            "downlinkCapacity": 100,
            "congestion": true
        }
    }
}
EOF

docker run -d --net=host --name=v2ray --restart=always -v ~/v2ray/config.json:/etc/v2ray/config.json v2fly/v2fly-core:v4.45.2
