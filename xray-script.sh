#!/bin/bash
# xray一键安装脚本
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
mkdir -p ~/xray/config
mkdir -p ~/xray/log

if [ ! -s ~/xray/config/$DOMAIN.key ] || [ ! -s ~/xray/config/$DOMAIN.pem ]; then
    docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --set-default-ca --server letsencrypt
    docker run --rm -it -v ~/acme.sh:/acme.sh --net=host neilpang/acme.sh --issue -d $DOMAIN --keylength ec-256 --standalone
    docker run --rm -it -v ~/acme.sh:/acme.sh -v ~/xray/config:/etc/xray --net=host neilpang/acme.sh --install-cert -d $DOMAIN --ecc --key-file /etc/xray/$DOMAIN.key --fullchain-file /etc/xray/$DOMAIN.pem
    echo "0 0 * * * docker run --rm -it --net=host -v ~/acme.sh:/acme.sh -v ~/xray/config:/etc/xray neilpang/acme.sh --cron > /dev/null" >> /var/spool/cron/crontabs/root
fi

cat > ~/nginx/nginx.conf<<-EOF
user nginx;
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
    listen 81 http2;
    server_name $DOMAIN;
    root /usr/share/nginx/html;
    location / {
        proxy_ssl_server_name on;
        proxy_pass https://bing.ioliu.cn;
        proxy_set_header Accept-Encoding '';
        sub_filter "bing.ioliu.cn" "$DOMAIN";
        sub_filter_once off;
    }
        location = /robots.txt {}
}
EOF

docker run -d --net=host --name=nginx --restart=always -v ~/nginx/nginx.conf:/etc/nginx/nginx.conf -v ~/nginx/conf.d:/etc/nginx/conf.d nginx

cat > ~/v2ray/config/config.json<<-EOF
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
            "port": 29545,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "email": "user1",
                        "id": "a1521187-6faa-412d-861d-cccf29c6217f",
                        "level": 1,
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "http/1.1",
                        "dest": 80
                    },
                    {
                        "alpn": "h2",
                        "dest": 81
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "serverName": "$DOMAIN",
                    "alpn": ["http/1.1", "h2"],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/bitdc.top.pem",
                            "keyFile": "/etc/xray/bitdc.top.key"
                        }
                    ]
                }
            }
        },
        {
            "port": 29546,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "email": "user2",
                        "id": "a1521187-6faa-412d-861d-cccf29c6217f",
                        "level": 1,
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "http/1.1",
                        "dest": 80
                    },
                    {
                        "alpn": "h2",
                        "dest": 81
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "serverName": "$DOMAIN",
                    "alpn": ["http/1.1", "h2"],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/bitdc.top.pem",
                            "keyFile": "/etc/xray/bitdc.top.key"
                        }
                    ]
                }
            }
        },
        {
            "port": 29547,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "email": "user3",
                        "id": "a1521187-6faa-412d-861d-cccf29c6217f",
                        "level": 1,
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "http/1.1",
                        "dest": 80
                    },
                    {
                        "alpn": "h2",
                        "dest": 81
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "serverName": "$DOMAIN",
                    "alpn": ["http/1.1", "h2"],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/bitdc.top.pem",
                            "keyFile": "/etc/xray/bitdc.top.key"
                        }
                    ]
                }
            }
        },
        {
            "port": 29548,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "email": "user4",
                        "id": "a1521187-6faa-412d-861d-cccf29c6217f",
                        "level": 1,
                        "flow": "xtls-rprx-direct"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "alpn": "http/1.1",
                        "dest": 80
                    },
                    {
                        "alpn": "h2",
                        "dest": 81
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "serverName": "$DOMAIN",
                    "alpn": ["http/1.1", "h2"],
                    "certificates": [
                        {
                            "certificateFile": "/etc/xray/bitdc.top.pem",
                            "keyFile": "/etc/xray/bitdc.top.key"
                        }
                    ]
                }
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

docker run -d --net=host --name=xray --restart=always -e TZ=Asia/Shanghai -v ~/xray/config:/etc/xray -v ~/xray/log:/var/log/xray teddysun/xray:1.7.5
