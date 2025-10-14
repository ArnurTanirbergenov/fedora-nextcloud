#!/bin/bash
# ==============================================
# Fedora Cloud Infrastructure Setup Script
# Author: <Your Name>
# Date: <Date>
# ==============================================

set -e
echo "=== Starting Fedora Cloud setup ==="

# 1. Create required groups
echo "=== Creating groups ==="
sudo groupadd -f admin
sudo groupadd -f auditor
sudo groupadd -f automation_bot
sudo groupadd -f nextcloud
sudo groupadd -f mariadb
sudo groupadd -f webserver
sudo groupadd -f backup
sudo groupadd -f clouduser
sudo groupadd -f cloudusers

# 2. Create users and assign groups
echo "=== Creating users ==="
sudo useradd -m -G admin cloudadmin || echo "User cloudadmin already exists"
sudo useradd -m -G auditor cloudauditor || echo "User cloudauditor already exists"
sudo useradd -m -G automation_bot autobot || echo "User autobot already exists"
sudo useradd -m -G nextcloud nextcloudsvc || echo "User nextcloudsvc already exists"
sudo useradd -m -G mariadb mariadbsvc || echo "User mariadbsvc already exists"
sudo useradd -m -G webserver websvcs || echo "User websvcs already exists"
sudo useradd -m -G backup backupsys || echo "User backupsys already exists"
sudo useradd -m -G cloudusers clouduser || echo "User clouduser already exists"

# 3. Create required directories
echo "=== Creating required directories ==="
sudo mkdir -p /var/www/html/nextcloud
sudo mkdir -p /srv/nextcloud_data
sudo mkdir -p /var/lib/mysql
sudo mkdir -p /var/backups

# 4. Assign ownership
echo "=== Assigning ownership ==="
sudo chown -R nextcloudsvc:nextcloud /var/www/html/nextcloud
sudo chown -R nextcloudsvc:nextcloud /srv/nextcloud_data
sudo chown -R mariadbsvc:mariadb /var/lib/mysql
sudo chown -R websvcs:webserver /var/www/html
sudo chown -R backupsys:backup /var/backups

# 5. Configure sudoers permissions
echo "=== Configuring sudoers permissions ==="
echo "%admin ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/admins
echo "autobot ALL=(ALL) NOPASSWD: /bin/systemctl restart nginx, /bin/systemctl restart mariadb" | sudo tee /etc/sudoers.d/autobot

sudo chmod 440 /etc/sudoers.d/*

# 6. Add user to wheel group (if needed)
sudo usermod -aG wheel arnur || true

# 7. Enable SSH service
echo "=== Enabling SSH service ==="
sudo systemctl enable --now sshd

# 8. Configure firewall for SSH
echo "=== Configuring firewall ==="
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# 9. SSH key setup for autobot
echo "=== Generating SSH key for autobot ==="
sudo -u autobot mkdir -p /home/autobot/.ssh
sudo -u autobot chmod 700 /home/autobot/.ssh
sudo -u autobot ssh-keygen -t ed25519 -C "autobot@fedora" -N "" -f /home/autobot/.ssh/id_ed25519
# Note: The ssh-copy-id step requires a remote system; it's documented below

echo "=== Setup complete! ==="
echo "Next step (manual):"
echo "Run 'ssh-copy-id autobot@10.0.2.15' from the autobot user to copy the key."
