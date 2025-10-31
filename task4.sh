#!/bin/bash

# Task 4 automation script
# -------------- Install Docker --------------
sudo dnf install -y docker
sudo systemctl enable --now docker

# -------------- Create project folder --------------
mkdir -p ~/docker-hello
cd ~/docker-hello

# -------------- Create index.html --------------
cat > index.html <<EOF
<h1>Hello Arnur Cloud</h1>
<p>Task 3 Docker container ready</p>
EOF

# -------------- Create Dockerfile --------------
cat > Dockerfile <<EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOF

# -------------- Build and tag Docker image --------------
sudo docker build -t arnurio/hello-cloud:1.0 .

# -------------- Push image to DockerHub (assumes docker login) --------------
sudo docker push arnurio/hello-cloud:1.0 || echo "Run 'docker login' first"

# -------------- Create systemd unit for container --------------
sudo bash -c 'cat > /etc/systemd/system/cloudapp.service' <<EOF
[Unit]
Description=Docker Hello Cloud Service
After=network.target docker.service
Requires=docker.service

[Service]
Restart=always
ExecStartPre=/usr/bin/docker rm -f hello-service || true
ExecStart=/usr/bin/docker run --name hello-service -p 8080:80 arnurio/hello-cloud:1.0
ExecStop=/usr/bin/docker stop hello-service
ExecStopPost=/usr/bin/docker rm -f hello-service || true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable container service
sudo systemctl daemon-reload
sudo systemctl enable --now cloudapp.service

# -------------- Create backup script --------------
sudo bash -c 'cat > /usr/local/bin/backup_nextcloud.sh' <<EOF
#!/bin/bash
DATE=\$(date +%F-%H-%M)
tar -czf /var/backups/nextcloud_\$DATE.tar.gz /srv/nextcloud_data
EOF
sudo chmod +x /usr/local/bin/backup_nextcloud.sh

# -------------- Create cleanup script --------------
sudo bash -c 'cat > /usr/local/bin/cleanup_temp.sh' <<EOF
#!/bin/bash
find /tmp -type f -mtime +3 -delete
EOF
sudo chmod +x /usr/local/bin/cleanup_temp.sh

# -------------- Create backup service --------------
sudo bash -c 'cat > /etc/systemd/system/backup_nc.service' <<EOF
[Unit]
Description=Backup Nextcloud data

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup_nextcloud.sh
EOF

# -------------- Create backup timer --------------
sudo bash -c 'cat > /etc/systemd/system/backup_nc.timer' <<EOF
[Unit]
Description=Run Nextcloud backup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# -------------- Create cleanup service --------------
sudo bash -c 'cat > /etc/systemd/system/cleanup_tmp.service' <<EOF
[Unit]
Description=Cleanup tmp files older than 3 days

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cleanup_temp.sh
EOF

# -------------- Create cleanup timer --------------
sudo bash -c 'cat > /etc/systemd/system/cleanup_tmp.timer' <<EOF
[Unit]
Description=Run cleanup every 6 hours

[Timer]
OnCalendar=*-*-* *:0/6:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# -------------- Enable timers --------------
sudo systemctl daemon-reload
sudo systemctl enable --now backup_nc.timer
sudo systemctl enable --now cleanup_tmp.timer

echo "Task 4 automation complete!"
echo "Check timers with:"
echo " systemctl list-timers --all"
