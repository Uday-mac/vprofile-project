#!/bin/bash

sudo apt update

sudo apt install openjdk-21-jdk -y

java -version

cd /opt

sudo curl -L -O https://download.sonatype.com/nexus/3/nexus-3.98.1-01-linux-x86_64.tar.gz

sudo tar -xvzf nexus-3.98.1-01-linux-x86_64.tar.gz

sudo mv nexus-3.98.1-01 nexus

sudo rm nexus-3.98.1-01-linux-x86_64.tar.gz

sudo useradd nexus

sudo chown -R nexus:nexus /opt/nexus  

sudo chown -R nexus:nexus /opt/sonatype-work  

sudo tee /opt/nexus/bin/nexus.rc > /dev/null <<EOF
run_as_user="nexus"
EOF

sudo tee /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
TimeoutStartSec=300
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

sudo systemctl start nexus

sudo systemctl enable nexus

