#!/usr/bin/env bash

# INSTRUCTIONS to run this script
# sudo apt-get install git -y
# mkdir -p /tmp/repos
# cd /tmp/repos
# git clone -b master https://github.com/mattjcowan/app.git
# ./app/lib/setup-server.sh

dir=$(pwd)
cdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$APP_NAME" = "" ]; then APP_NAME=app; fi
if [ "$DEPLOY_DIR" = "" ]; then DEPLOY_DIR=/var/www/app; fi
if [ "$NODE_SOURCE_URL" = "" ]; then NODE_SOURCE_URL=https://deb.nodesource.com/setup_10.x; fi
if [ "$INSTALL_DOTNET_SDK" = "" ]; then INSTALL_DOTNET_SDK=0; fi
if [ "$DOTNET_VERSION" = "" ]; then DOTNET_VERSION=dotnet-sdk-2.2; fi
if [ "$CDN_HOSTS" = "" ]; then CDN_HOSTS="https://ssl.google-analytics.com https://fonts.googleapis.com https://themes.googleusercontent.com https://cdn.jsdelivr.net https://maxcdn.bootstrapcdn.com https://code.jquery.com https://cdnjs.cloudflare.com"; fi

#####################################
# Don't change below this line

sudo mkdir -p $DEPLOY_DIR
if [ ! -d $DEPLOY_DIR/dist ]; then 
    sudo mkdir -p $DEPLOY_DIR/dist
    sudo mkdir -p $DEPLOY_DIR/data
fi
if [ -d $cdir/../dist ]; then 
    sudo cp -r $cdir/../dist $DEPLOY_DIR/dist
fi

PUBLIC_IP="$(dig +short myip.opendns.com @resolver1.opendns.com)"

# install common libraries
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get install nano -y
sudo apt-get install git -y
sudo apt-get install sqlite3 -y
sudo apt-get install libsqlite3-dev -y
sudo apt-get install zip -y
sudo apt-get install unzip -y
sudo apt-get install ufw -y
sudo apt-get install python-pip -y

# install firewall
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
yes | sudo ufw enable
sudo ufw reload

# setup autoupgrades
if [ ! -f /etc/apt/apt.conf.d/20auto-upgrades ]; then
sudo apt-get install -y unattended-upgrades
sudo apt-get autoremove
cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "3";
APT::Periodic::Unattended-Upgrade "1";
EOL
fi

# install node
curl -sL $NODE_SOURCE_URL | sudo bash -
sudo apt-get update && sudo apt-get -y upgrade
yes | sudo apt-get autoremove
sudo apt-get install -y nodejs 
sudo apt-get install -y build-essential
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install -y gcc g++ make
sudo apt-get install -y yarn
yes | sudo apt-get autoremove

# install dotnet pre-reqs and sdk (if applicable)
sudo apt-get install -y liblttng-ust0 libcurl3 libssl1.0.0 libkrb5-3 zlib1g
sudo apt-get install -y apt-transport-https
sudo apt-get update

if [[ "$INSTALL_DOTNET_SDK" == "1" ]] ; then 
    . /etc/os-release
    if ! dotnet_loc="$(type -p "dotnet")" || [[ -z $dotnet_loc ]]; then
        sudo apt-get install -y liblttng-ust0 libcurl3 libssl1.0.0 libkrb5-3 zlib1g 
        if [[ "$VERSION_ID" == *"18."* ]] ; then 
            wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo add-apt-repository universe
            sudo apt-get install -y libicu60
        elif [[ "$VERSION_ID" == *"16."* ]] ; then 
            wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            sudo apt-get install -y libicu55
        else
            echo "Unsupported flavor of ubuntu: $ID.$VERSION_ID"
            exit 0
        fi
        sudo apt-get install -y apt-transport-https
        sudo apt-get update
        sudo apt-get install -y $DOTNET_VERSION
    else
        echo "dotnet already installed"
    fi
fi

# install nginx
if ! nginx_loc="$(type -p "nginx")" || [[ -z $nginx_loc ]]; then
    sudo apt-get install nginx -y
    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "nginx already installed"
fi

# install self-signed cert
if [ ! -f /etc/nginx/snippets/self-signed.conf ]; then
sudo openssl req -x509 -nodes -days 2000 -newkey rsa:4096 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj /C=US/ST=Illinois/L=Chicago/O=Startup/CN=$PUBLIC_IP
sudo openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096 > /dev/null 2>&1

cat >/etc/nginx/snippets/self-signed.conf <<EOL
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOL

cat >/etc/nginx/snippets/ssl-params.conf <<EOL
# from https://cipherli.st/ and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
EOL
    echo "self-signed cert created"
else
    echo "self-signed cert already created"
fi

# # install dist/data
# cd $DEPLOY_DIR
# git clone -b master https://github.com/mattjcowan/app.git .
# rm -Rf ./.git
# rm .gitignore
# rm package.json
# rm README.md
# mkdir -p data

# setup system.d service
if [ ! -f "/etc/systemd/system/app.service" ]; then
cat >/etc/systemd/system/app.service <<EOL
[Unit]
Description=app service
[Service]
WorkingDirectory=$DEPLOY_DIR/dist
ExecStart=app
Restart=always
RestartSec=10
SyslogIdentifier=dotnet-app
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=DOTNET_CLI_TELEMETRY_OPTOUT=1
[Install]
WantedBy=multi-user.target
EOL
fi

# configure nginx default site
cat >/etc/nginx/sites-available/default <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $PUBLIC_IP;
    return 301 https://\$host\$request_uri;
}

map \$scheme \$hsts_header {
    https   max-age=31536000;
}

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;    
    
    # Optional, not necessary for .net proxy only setup
    # root $DEPLOY_DIR/dist;
    # index index.php index.html index.htm index.nginx-debian.html;

    server_tokens off;
    server_name $PUBLIC_IP;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;
    location / {
        proxy_pass http://localhost:5000;

        # WebSockets Support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        # proxy_set_header Connection keep-alive;
        proxy_set_header Connection \$http_connection;
        
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
        proxy_ignore_client_abort off;
        proxy_intercept_errors on;
        proxy_pass_request_headers on;
        proxy_hide_header X-Content-Type-Options;

        default_type "text/html";

        # The following are needed for a perfect security score
        # get a grade A in security at https://securityheaders.io
        add_header X-Frame-Options SAMEORIGIN always;
        add_header X-Content-Type-Options nosniff always;
        #add_header X-Content-Type-Options "" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Strict-Transport-Security \$hsts_header;
        # add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload";
        add_header Content-Security-Policy "default-src https: 'self' $CDN_HOSTS; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; font-src 'self'; object-src 'none'; media-src 'self'; form-action 'self'; frame-ancestors 'self';" always;
        add_header Referrer-Policy "no-referrer";
        client_max_body_size 500m;
    }
}
EOL
fi

sudo chown -R www-data:www-data $DEPLOY_DIR/
sudo chmod -R 755 $DEPLOY_DIR/
echo "app permissions set"

sudo systemctl enable app.service
sudo systemctl stop app.service
sudo systemctl start app.service
echo "app service (re)started"

sudo systemctl stop nginx
sudo systemctl start nginx
echo "nginx service (re)started"

# When using Cloudflare

# The following ensures that firewall rules exist for cloudflare IPs.
# This is useful for locking down all http/https traffic through Cloudflare.

# See: https://github.com/Paul-Reed/cloudflare-ufw
# IPs also visible at: https://www.cloudflare.com/ips/

# ```
# cd ~/
# mkdir -p /repos
# cd /repos
# git clone https://github.com/Paul-Reed/cloudflare-ufw
# sudo $cdir/cloudflare-ufw/./cloudflare-ufw.sh
# ```

# Set it up as a cronjob to update ufw IPs weekly

# ```
# sudo crontab -e
# ```

# using

# ```
# 0 0 * * 1 /root/repos/cloudflare-ufw/cloudflare-ufw.sh > /dev/null 2>&1
# ```