#!/bin/bash

sudo dnf update -y

sudo dnf install -y dnf-utils nano wget curl git tar unzip \
nginx mariadb-server mariadb \
php php-fpm php-mysqlnd php-xml php-gd php-mbstring php-intl php-json php-zip php-curl php-ldap php-bz2 php-gmp \
firewalld fail2ban policycoreutils-python-utils certbot python3-certbot-nginx \
rsync python3 pip sshpass expect bzip2 libxml2 libzip ImageMagick


sudo systemctl enable --now firewalld
sudo systemctl enable --now nginx
sudo systemctl enable --now mariadb
sudo systemctl enable --now php-fpm
sudo systemctl enable --now fail2ban


sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload


#Here i just googled like how to create script in another script and did it
cat << 'EOF' | sudo tee /usr/local/bin/smoke_test.sh > /dev/null
#!/bin/bash
echo "Testing services"
nginx -t && echo "Nginx"
mysqladmin ping && echo "MariaDB"
php -v | grep PHP && echo "PHP"
systemctl is-active firewalld && echo "Firewall"
systemctl is-active fail2ban && echo "Fail2Ban"
echo "Complete"
EOF

# Make it executable
sudo chmod +x /usr/local/bin/smoke_test.sh

sudo /usr/local/bin/smoke_test.sh
