#!/bin/bash
       # Is the driver installed?
       if [ -f /usr/bin/nvidia-smi ]; then
               # Can the driver find the GPU?
               VAR=$(/usr/bin/nvidia-smi)
               if [[ "$VAR" = "No devices were found" ]]; then
                       echo -e "No GPU Found. Rebooting"
                       sudo reboot now
               else
                       # Create the xorg config
                       wget -O nvidia-xorg.sh https://raw.githubusercontent.com/small-hack/smol-metal/main/nvidia-xorg.sh
                       sudo bash nvidia-xorg.sh
                       sudo systemctl restart gdm3
               fi
               # Is ECC mode enabled?
               ECC_MODE=$(nvidia-smi -q |grep -A1 "ECC Mode" |tail -1 |awk '{print $3}')
               if [[ "$ECC_MODE" = "Enabled" ]]; then
                       sudo nvidia-smi -e 0
                       sudo reboot now
               fi
               # Is vGPU activated?
               LICENSE_STATUS=$(nvidia-smi -q |grep "License" |tail -1| awk '{print $4}')
               if [[ "$LICENSE_STATUS" = "Unlicensed" ]]; then
                       mkdir -p /opt/docker/fastapi-dls/cert
                       cd /opt/docker/fastapi-dls/cert
                       openssl genrsa -out instance.private.pem 2048
                       openssl rsa -in instance.private.pem -outform PEM -pubout -out instance.public.pem
                       openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout webserver.key -out webserver.crt -subj "/C=EU/ST=Noord-Holland/L=Amsterdam/O=Dis/CN=www.example.com"
                       docker run -d --restart unless-stopped --name vgpu \
                       -e DLS_URL=${ip_address} \
                       -e DLS_PORT=443 \
                       -p 443:443 \
                       -v /opt/docker/fastapi-dls/cert:/app/cert \
                       -v dls-db:/app/database collinwebdesigns/fastapi-dls:latest
                       echo "ServerAddress=${ip_address}" >> /etc/nvidia/gridd.conf
                       echo "ServerPort=443" >> /etc/nvidia/gridd.conf
                       echo "FeatureType=0" >> /etc/nvidia/gridd.conf
                       sleep 10
                       wget --no-check-certificate -O /etc/nvidia/ClientConfigToken/client_configuration_token_$(date '+%d-%m-%Y-%H-%M-%S').tok https://${ip_address}/-/client-token
                       sudo systemctl restart nvidia-gridd.service
               fi
               # Is NiceDCV installed?
               DCV_PATH=$(which dcv)
               if [[ -z "$DCV_PATH"  ]]; then
                       # install niceDCV
                       wget https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/Servers/nice-dcv-2023.1-16388-ubuntu2204-x86_64.tgz
                       tar zxvf nice-dcv-2023.1-16388-ubuntu2204-x86_64.tgz
                       sudo dpkg -i nice-dcv-2023.1-16388-ubuntu2204-x86_64/*.deb
                       sudo usermod -aG video dcv
                       sudo systemctl isolate multi-user.target
                       sudo dcvgladmin enable
                       sudo systemctl isolate graphical.target
                       sudo dcvgldiag
                       sudo systemctl enable dcvserver
                       sudo systemctl start dcvserver
               else
                       sudo dcv create-session --owner ${username} ${username}
               fi
       else
               # Has Cloud-Init run?
               if [ -f /done.txt ]; then
                       # If yes, install the driver
                       sudo mkdir -p /tmp/nvidia/
                       sudo cp -r /media/nvidia~1.run /tmp/nvidia/nvidia~1.run
                       DIR=$(pwd); cd /tmp/nvidia; bash nvidia~1.run -x; cd "$DIR"
                       DIR=$(pwd); cd /tmp/nvidia/NVIDIA-Linux-x86_64-535.154.05-grid; ./nvidia-installer --compat32-prefix=/usr --compat32-libdir=lib32 --dkms --silent --install-compat32-libs --no-check-for-alternate-installs --no-backup; cd "$DIR"
                       # enable system services
                       sudo systemctl enable gdm3
                       sudo reboot now
               else
                       # If No, let Cloud-Init run
                       exit 0
               fi
       fi
