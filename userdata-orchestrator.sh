#!/bin/bash
# Update the package list
sudo apt update -y
sudo apt upgrade -y

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
ExecStart=/usr/local/bin/bacalhau serve --orchestrator -c WebUI.Enabled=true -c WebUI.Listen=:8483
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

# Check the status of Bacalhau service (optional, can be removed)
sudo systemctl status bacalhau.service