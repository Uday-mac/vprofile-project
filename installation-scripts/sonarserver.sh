#!/bin/bash

#installing java
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk
sudo update-alternatives --config java
java -version

# Install PostgreSQL database
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

sudo echo "postgres:admin123" | chpasswd
sudo runuser -l postgres -c "createuser sonar"
sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;"
sudo systemctl restart  postgresql

sudo cp /etc/sysctl.conf /root/sysctl.conf_backup
sudo tee /etc/sysctl.conf <<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF
sysctl -p

sudo cp /etc/security/limits.conf /root/sec_limit.conf_backup
sudo tee /etc/security/limits.conf <<EOF
sonarqube - nofile 65536
sonarqube - nproc 4096
EOF

sudo useradd -m -d /opt/sonarqube -s /bin/bash sonar
cd /tmp
curl -L -o sonarqube.zip "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-26.11.0.134175.zip"
sudo apt-get install unzip -y
sudo unzip sonarqube.zip
sudo mv sonarqube-26.11.0.134175/* /opt/sonarqube
sudo chown -R sonar:sonar /opt/sonarqube

sudo tee /opt/sonarqube/conf/sonar.properties <<EOF
sonar.jdbc.username=sonar
sonar.jdbc.password=admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOF

sudo tee /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096


[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable sonarqube.service
sudo systemctl start sonarqube.service
#systemctl status -l sonarqube.service
apt-get install nginx -y
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

sudo tee /etc/nginx/sites-available/sonarqube <<EOF
server{
    listen      80;
    server_name sonarqube.groophy.in;

    access_log  /var/log/nginx/sonar.access.log;
    error_log   /var/log/nginx/sonar.error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
              
        proxy_set_header    Host            \$host;
        proxy_set_header    X-Real-IP       \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
EOF

ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
systemctl enable nginx.service
#systemctl restart nginx.service
sudo ufw allow 80,9000,9001/tcp

echo "System reboot in 30 sec"
sleep 30
reboot
