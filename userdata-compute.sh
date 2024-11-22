#!/bin/bash
# Update the package list
sudo apt update -y
sudo apt upgrade -y

# Install + Configure Nginx
sudo apt install -y nginx
systemctl enable nginx
systemctl start nginx

# Install + Configure Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo docker --version

curl -sL https://get.bacalhau.org/install.sh | bash

# Create a systemd service for Bacalhau
cat <<EOL | sudo tee /etc/systemd/system/bacalhau.service
[Unit]
Description=Bacalhau Orchestrator Service
After=network.target docker.service

[Service]
ExecStart=/usr/local/bin/bacalhau serve --compute -c Compute.Orchestrators=188.245.204.13:4222 -c Compute.Enabled=true --config Compute.AllowListedLocalPaths="/var/www/html:rw"
Restart=always
RestartSec=3
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to apply the new service
sudo systemctl daemon-reload

# Enable Bacalhau service to start on boot
sudo systemctl enable bacalhau.service

# Start Bacalhau service
sudo systemctl start bacalhau.service

# Install inotify-tools for directory monitoring
sudo apt install -y inotify-tools

# Create the SSL watcher script
sudo cat <<'EOF' > /usr/local/bin/cert-watch.sh
#!/bin/bash

# Directory to watch
WATCH_DIR="/etc/nginx/ssl"

# Command to restart NGINX
RESTART_CMD="sudo systemctl reload nginx"

# Log file for script activity
LOG_FILE="/var/log/cert-watch.log"

# Ensure the log file exists
sudo touch "$LOG_FILE"
sudo chmod 644 "$LOG_FILE"

echo "$(date): Starting cert watch script." >> "$LOG_FILE"

# Function to restart NGINX and log
restart_nginx() {
    echo "$(date): Certificate change detected. Reloading NGINX." >> "$LOG_FILE"
    $RESTART_CMD && echo "$(date): NGINX reloaded successfully." >> "$LOG_FILE" || echo "$(date): Failed to reload NGINX." >> "$LOG_FILE"
}

# Watch the directory for changes
inotifywait -m -e close_write,move,create,delete "$WATCH_DIR" | while read -r path action file; do
    echo "$(date): Change detected: $file ($action)" >> "$LOG_FILE"
    restart_nginx
done
EOF

# Make the watcher script executable
sudo chmod +x /usr/local/bin/cert-watch.sh

# Create a systemd service for the certificate watcher
cat <<EOL | sudo tee /etc/systemd/system/cert-watch.service
[Unit]
Description=Certificate Watcher to Reload NGINX
After=network.target

[Service]
ExecStart=/usr/local/bin/cert-watch.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to apply the new service
sudo systemctl daemon-reload

# Enable the cert-watch service to start on boot
sudo systemctl enable cert-watch.service

# Start the cert-watch service
sudo systemctl start cert-watch.service
