#!/bin/bash

# Check if we are running as sudo, if not, exit
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Maybe try 'sudo !!'"
    exit
fi

# Update the system
/usr/bin/apt update
/usr/bin/apt upgrade -y

# Install base packages
PACKAGES="
git
curl
wget
unzip
zip
htop
vim
sed
apt-transport-https
ca-certificates
software-properties-common
fail2ban
dos2unix
unattended-upgrades
gnupg
gnupg-agent
lsb-release
rsync
neofetch
dialog
"
/usr/bin/apt install -y "$(tr '\n' ' ' <<< "$PACKAGES")"

# Lockdown SSH
/usr/bin/sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#PermitRootLogin no/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
/usr/bin/sed -i 's/#Port 22/Port 1000/g' /etc/ssh/sshd_config
/usr/bin/systemctl restart sshd

# Disable MOTDs
/usr/bin/touch ~/.hushlogin

# Start fail2ban
/usr/bin/systemctl enable --now fail2ban

# Setup unattended upgrades
/usr/bin/cp ./resources/unattended-upgrades/* /etc/apt/apt.conf.d/

# sysctl tweaks
/usr/bin/cp ./resources/sysctl.conf /etc/sysctl.conf
/usr/sbin/sysctl -p

# Install docker
## INFO: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
/usr/bin/sudo /usr/bin/mkdir -p /etc/apt/keyrings
/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | /usr/bin/sudo /usr/bin/gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | /usr/bin/sudo /usr/bin/tee /etc/apt/sources.list.d/docker.list > /dev/null
/usr/bin/sudo /usr/bin/apt-get update
/usr/bin/sudo /usr/bin/apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
/usr/bin/systemctl enable --now docker

# Install & Configure Apache
PACKAGES="
apache2
php
php-bcmath
php-bz2
php-curl
php-intl
php-mbstring
php-mysql
php-readline
php-xml
php-zip
php-apcu
php-cli
php-common
php-fpm
php-gd
php-igbinary
php-imagick
php-json
php-pear
php-redis
php-dev
php-gmp
php-opcache
php-soap
libapache2-mod-php
"
/usr/bin/apt install -y "$(tr '\n' ' ' <<< "$PACKAGES")"

APACHE_MODULES="
actions
headers
proxy
proxy_ajp
proxy_balancer
proxy_connect
proxy_fcgi
proxy_html
proxy_http
proxy_wstunnel
rewrite
slotmem_shm
socache_shmcb
ssl
xml2enc
http2
"
/usr/sbin/a2enmod "$(tr '\n' ' ' <<< "$APACHE_MODULES")"
/usr/bin/systemctl restart apache2

# Crontabs
(/usr/bin/crontab -l ; echo "0 2 * * * docker image prune -a -f && docker volume prune -f && docker network prune -f") | /usr/bin/crontab -

# Use docker-compose to start all the containers
echo "Done! Please 'cd resources' and edit docker-compose.yml with your secrets, then run 'docker compose up -d'"

cd ~ || exit
