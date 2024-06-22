# Smol-Metal

Notes for configuring Debian Bookworm nodes for use as VPS hosts.
The steps below setup the system to be further controlled by ansible. Eventually most of this will move into a cloid-init or pre-seed files.

## Upgrading a host from Debian11 to Debian12

Fix apt sources / Upgrade: https://wiki.debian.org/DebianUpgrade
  
  ```bash
  cat << EOF > /etc/apt/sources.list
  deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

  deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free
  deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free

  deb http://deb.debian.org/debian bookworm-updates main contrib non-free
  deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free

  deb http://deb.debian.org/debian bookworm-backports main
  deb http://deb.debian.org/debian bullseye-backports main
  EOF
  
  apt-get update && \
  apt-get upgrade -y && \
  apt-get full-upgrade -y
  
  reboot
  ```

## Install Proxmox kernel

- List available kernels
  
  ```bash
  # standard debian 
  apt list linux-*image-*
  apt list linux-*headers-*

  # proxmox
  apt list pve-kernel-*
  ```

- Installing proxmox pve kernel and headers on debian

  ```bash
  wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

  cat << EOF > /etc/apt/sources.list
  deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

  deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free
  deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free

  deb http://deb.debian.org/debian bookworm-updates main contrib non-free
  deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free

  deb http://deb.debian.org/debian bookworm-backports main
  deb http://deb.debian.org/debian bullseye-backports main

  deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
  EOF
  
  apt-get update 
  apt-get install pve-kernel-6.2/stable
  apt-get install pve-headers-6.2


  cat << EOF > /etc/apt/sources.list
  deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware

  deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free
  deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free

  deb http://deb.debian.org/debian bookworm-updates main contrib non-free
  deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free

  deb http://deb.debian.org/debian bookworm-backports main
  deb http://deb.debian.org/debian bullseye-backports main
  
  EOF

  apt-get remove apparmor
  apt-get install apparmor
  ```

- Donwload meta package from source if its not in the apt list
  
  - https://packages.debian.org/search?keywords=linux-image-amd64

- List all installed kernels and headers

  ```bash
  dpkg --list | egrep -i --color 'linux-image|linux-headers'
  ```

- Remove undesired kernels and headers

  ```bash
  apt-get --purge remove linux-image-6.1.0-12-amd64 linux-image-amd64 
  ```

- prevent changes

  ```bash
  sudo apt-mark hold pve-kernel-6.2/stable
  sudo apt-mark hold pve-headers-6.2
  ```
- reboot


## Ubuntu alternative package mirror

  ```bash
  cat << EOF > /etc/apt/sources.list
  deb http://de.archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
  # deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse

  deb http://de.archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
  # deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse

  deb http://de.archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
  # deb-src http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse

  deb http://de.archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse
  # deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse

  deb http://archive.canonical.com/ubuntu/ jammy partner
  # deb-src http://archive.canonical.com/ubuntu/ jammy partner
  
  EOF
  sudo apt-get update && \
  sudo apt-get upgrade -y && \
  sudo apt-get full-upgrade -y
  
  reboot
  ```
  
## Initial Setup:

1. install basic dependancies (Run as Root)

 - Apt Packages:
 
    ```bash
    apt-get update && \
      apt-get install -y wireguard \
      ssh-import-id \
      sudo \
      curl \
      tmux \
      netplan.io \
      apt-transport-https \
      ca-certificates \
      software-properties-common \
      htop \
      git-extras \
      rsyslog \
      fail2ban \
      vim \
      gpg \
      open-iscsi \
      nfs-common \
      ncdu \
      zip \
      unzip \
      iotop && \
      sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && \
      sudo chmod +x /usr/bin/yq && \
      sudo systemctl enable fail2ban && \
      sudo systemctl start fail2ban

    # VM guest utils
    apt update && apt -y install qemu-guest-agent && \
    systemctl enable qemu-guest-agent
    systemctl start qemu-guest-agent

    # Optional Go + Seaweedfs cli
    wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:/usr/bin" >> /home/friend/.bash_profile
    sudo -u friend -i go install -x github.com/seaweedfs/seaweedfs/weed@latest
    mv /home/friend/go/bin/weed /usr/local/bin/
    mkdir /home/friend/shared
    sudo weed mount -filer=seaweedfs-filer.seaweedfs.svc.cluster.local:8888 \
      -dir=/home/friend/shared \
      -filer.path=/friend/shared -volumeServerAccess=filerProxy

    # Optional Basic Desktop
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
      xinit \
      xorg \
      firefox-esr \
      xfce4 \
      xfce4-goodies \
      x11-utils \
      x11vnc \
      xvfb \
      dbus-x11 && \
      echo -e "allowed_users=anybody\nneeds_root_rights=yes" | sudo tee /etc/X11/Xwrapper.config > /dev/null

    # Install sunhine
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake=3.25.* \
    doxygen \
    git \
    graphviz \
    libayatana-appindicator3-dev \
    libcap-dev \
    libcurl4-openssl-dev \
    libdrm-dev \
    libevdev-dev \
    libminiupnpc-dev \
    libnotify-dev \
    libnuma-dev \
    libopus-dev \
    libpulse-dev \
    libssl-dev \
    libva-dev \
    libvdpau-dev \
    libwayland-dev \
    libx11-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    libxcb1-dev \
    libxfixes-dev \
    libxrandr-dev \
    libxtst-dev \
    nodejs \
    npm \
    python3.11 \
    python3.11-venv \
    udev \
    wget \
    x11-xserver-utils \
    xvfb

    mkdir -p /build/cuda
    export CUDA_VERSION="12.0.0"
    export CUDA_BUILD="525.60.13"
    cuda_prefix="https://developer.download.nvidia.com/compute/cuda/"
    url="${cuda_prefix}${CUDA_VERSION}/local_installers/cuda_${CUDA_VERSION}_${CUDA_BUILD}_linux${cuda_suffix}.run"
    wget "$url" --progress=bar:force:noscroll -q --show-progress -O ./cuda.run
    chmod a+x ./cuda.run
    ./cuda.run --toolkit --toolkitpath=/build/cuda --no-opengl-libs --no-man-page --no-drm
  
    export VERSION="v0.23.1"
    export PLATFORM="debian-bookworm"
    export ARCH="amd64.deb"
    export REPO="LizardByte/Sunshine/"
    wget https://github.com/$REPO/releases/download/$VERSION/sunshine-$PLATFORM-$ARCH
    apt-get isntall -f ./sunshine-$PLATFORM-$ARCH

    echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | \
    sudo tee /etc/udev/rules.d/60-sunshine.rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo modprobe uinput
    sudo setcap -r $(readlink -f $(which sunshine))

    mkdir -p /home/friend/.config/systemd/user
    
    cat << EOF > /home/friend/.config/systemd/user/sunshine.service
    [Unit]
    Description=Sunshine self-hosted game stream host for Moonlight.
    StartLimitIntervalSec=500
    StartLimitBurst=5

    [Service]
    ExecStart=/usr/bin/sunshine
    Restart=on-failure
    RestartSec=5s
    #Flatpak Only
    #ExecStop=flatpak kill dev.lizardbyte.sunshine

    [Install]
    WantedBy=graphical-session.target
    EOF

    sudo chown -R friend:friend /home/friend/.config
    systemctl --user enable sunshine
    systemctl --user start sunshine

    # Install nicedcv
    export FILE_NAME="nice-dcv-2023.1-16388-ubuntu2204-x86_64"
    wget https://d1uj6qtbmh3dt5.cloudfront.net/2023.1/Servers/$FILE_NAME.tgz
    tar -xvzf $FILE_NAME.tgz
    sudo apt-get install -y -f ./$FILE_NAME/*.deb

    sudo usermod -aG video dcv
    sudo sed -ie 's/#owner = ""/owner = "friend"/' /etc/dcv/dcv.conf
    sudo sed -ie 's/"1"/"0"/g' /etc/apt/apt.conf.d/20auto-upgrades
    sudo systemctl isolate multi-user.target
    sudo dcvgladmin enable
    sudo systemctl isolate graphical.target
    sudo dcvgldiag
    sudo systemctl enable dcvserver
    sudo systemctl start dcvserver

    dcv list-sessions
    
    
    
    ```
    
    Prometheus (Run this as root)
    ```bash
    wget -O /opt/node_exporter-1.6.1.linux-amd64.tar.gz https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz && \
    tar -xvf /opt/node_exporter-1.6.1.linux-amd64.tar.gz -C /opt && \
    rm /opt/node_exporter-1.6.1.linux-amd64.tar.gz && \
    ln -s node_exporter-1.6.1.linux-amd64 /opt/node_exporter
    
    wget https://raw.githubusercontent.com/small-hack/smol-metal/main/node-exporter.service && \
    sudo mv node-exporter.service /etc/systemd/system/node-exporter.service && \
    systemctl daemon-reload && \
    systemctl enable node-exporter && \
    systemctl restart node-exporter
    ```

2. Setup the user

    ```bash
    sudo useradd -s /bin/bash -d /home/friend/ -m -G sudo friend
    sudo echo "friend ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    sudo -u friend ssh-import-id-gh cloudymax
    sudo usermod -a -G kvm friend
    passwd friend
    ```
    
 3. Install Docker and Onboardme (Run as user, not as root)
    
    ```bash
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    ```
    Ubuntu
    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```
    
    Debian
    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```
    
    ```bash
    sudo apt-get update && \
    sudo apt-get install -y docker-ce && \
    sudo usermod -a -G docker friend
    ```

3. Brew and Python3.11 (Run as User)
    ```
    wget -O setup.sh https://raw.githubusercontent.com/jessebot/onboardme/main/setup.sh
    . ./setup.sh 

    brew install bitwarden-cli b2-tools k9s neovim
    ```
    
4. Docker Compose (Run as User)
   
   ```bash
   mkdir -p ~/.docker/cli-plugins/
   curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
   chmod +x ~/.docker/cli-plugins/docker-compose
   docker compose version
   ```

5. Disable sleep

  ```bash
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```

6. set open files limits
  
  ```bash
  sudo sysctl fs.inotify.max_user_instances=1280
  sudo sysctl fs.inotify.max_user_watches=655360
  ```

## Networking

bridge the network adapter (Optional)
  
  ```bash
  # /etc/netplan/99-bridge.yaml
  network:
    bridges:
      br0:
        dhcp4: no
        dhcp6: no
        interfaces: [enp4s0]
        addresses: [192.168.50.101/24]
        routes:
          - to: default
            via: 192.168.50.1
        mtu: 1500
        nameservers:
          addresses: [192.168.50.50]
        parameters:
          stp: true
          forward-delay: 4
    ethernets:
      enp4s0:
        dhcp4: no
        dhcp6: no
    renderer: networkd
    version: 2

  sudo netplan --debug generate
  sudo netplan --debug apply
  ```
    
5. Setup Wireguard (Optional) (Run as Root)

    <details>
      <summary>Click to expand</summary>

    - Enable IP forwarding
    ```bash
    sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
    ```

    - Generate Server Keys
    ```bash
    cd /etc/wireguard
    wg genkey | tee privatekey | wg pubkey > publickey
    ```
    
    - Edit the wireguard config
    ```bash
    nano /etc/wireguard/wg0.conf
    ```

    - Server Config
    ```bash
    export SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/publickey)
    export SERVER_PRIVATE_KEY=$(sudo cat /etc/wireguard/privatekey)
    export NETWORK_INTERFACE="enp0s31f6"
    export WG_INTERFACE="wg0"
    export SERVER_PORT="51820"
    export WG_ADDRESS="10.2.0.1"

    cat << EOF > wg0.conf
    [Interface]
    Address = ${WG_ADDRESS}/24
    ListenPort = ${SERVER_PORT}
    PrivateKey = ${SERVER_PRIVATE_KEY}

    PostUp = iptables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${NETWORK_INTERFACE} -j MASQUERADE; ip6tables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${NETWORK_INTERFACE} -j MASQUERADE
    PostDown = iptables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${NETWORK_INTERFACE} -j MASQUERADE; ip6tables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${NETWORK_INTERFACE} -j MASQUERADE
    EOF
    ```

    - Client Config
    ```bash
    mkdir client && cd client
    wg genkey | tee privatekey | wg pubkey > publickey
    export SERVER_PUBLIC_KEY=$(cat ../publickey)
    export CLIENT_PRIVATE_KEY=$(cat privatekey)
    export SERVER_PUBLIC_IP="128.140.72.118"
    export SERVER_PORT="51820"
    export IP_ADDRESS="10.2.0.2"

    cat << EOF > wg0.conf
    [Interface]
    PrivateKey = ${PRIVATE_KEY}
    Address = ${IP_ADDRESS}/24

    [Peer]
    PublicKey = ${SERVER_PUBLIC_KEY}
    AllowedIPs = 10.2.0.0/24
    Endpoint = ${SERVER_PUBLIC_IP}:${SERVER_PORT}
    PersistentKeepalive = 15
    EOF
    ```

    - Enable wireguard as a service
    ```bash
    sudo systemctl enable wg-quick@wg0
    ```

    - Start the service
    ```bash
    sudo systemctl restart wg-quick@wg0
    ```
    </details>

5. Disable insecure ssh login options

    ```bash
    sudo wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/cloudymax/linux_notes/main/sshd_config

    sudo systemctl reload sshd
    ```

6. Setup PCI/IOMMU Passthrough (Optional)

    <details>
      <summary>Enable iommu via grub</summary>
  
    ```bash
    # /etc/default/grub
    GRUB_DEFAULT=0
    GRUB_TIMEOUT=5
    GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
    GRUB_CMDLINE_LINUX_DEFAULT="quiet preempt=voluntary iommu=pt amd_iommu=on intel_iommu=on"
    GRUB_CMDLINE_LINUX=""

    sudo update-grub
    sudo reboot now
    ```
  
    </details>


    <details>
      <summary>Setup GPU-Passthrough</summary>
  
    ```bash
    # See: https://github.com/small-hack/smol-gpu-passthrough

    wget https://raw.githubusercontent.com/small-hack/smol-gpu-passthrough/main/setup.sh

    bash setup.sh full_run NVIDIA
    sudo reboot now
    ```
  
    </details>

  vGPU Install (run all this as root)

    
  ```bash
  # /etc/default/grub
  GRUB_DEFAULT=0
  GRUB_TIMEOUT=5
  GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
  GRUB_CMDLINE_LINUX_DEFAULT="quiet preempt=voluntary iommu=pt amd_iommu=on intel_iommu=on"
  GRUB_CMDLINE_LINUX=""

  sudo update-grub

  echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> /etc/modules
  echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf
  update-initramfs -u -k all

  sudo reboot now
  ```
    
  ```console
  apt install -y git build-essential \
      dkms \
      mdevctl \
      firmware-misc-nonfree \
      linux-headers-amd64 \
      gcc \
      make \
      libvulkan1 \
      libglvnd-dev \
      uuid-runtime

  cd /root
  git clone https://gitlab.com/polloloco/vgpu-proxmox.git

  cd /opt
  git clone https://github.com/mbilker/vgpu_unlock-rs.git

  cd /tmp
  curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
  source $HOME/.cargo/env

  cd /opt/vgpu_unlock-rs/
  cargo build --release

  # Create a vgpu profile
  mkdir /etc/vgpu_unlock
  touch /etc/vgpu_unlock/profile_override.toml

  cat << EOF > /etc/vgpu_unlock/profile_override.toml
  [profile.nvidia-18]
  num_displays = 1
  display_width = 1920
  display_height = 1080
  max_pixels = 2073600
  cuda_enabled = 1
  frl_enabled = 0
  framebuffer = 0x1DC000000
  framebuffer_reservation = 0x24000000
  EOF

  mkdir /etc/systemd/system/{nvidia-vgpud.service.d,nvidia-vgpu-mgr.service.d}
  echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf
  echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf

  download driver
  wget https://f004.backblazeb2.com/file/buildstar-public-share/NVIDIA-GRID-Linux-KVM-535.54.06-535.54.03-536.25.zip
  unzip NVIDIA-GRID-Linux-KVM-535.54.06-535.54.03-536.25.zip
  cd Host_Drivers
  chmod +x NVIDIA-Linux-x86_64-535.54.06-vgpu-kvm.run
  ./NVIDIA-Linux-x86_64-535.54.06-vgpu-kvm.run --apply-patch ~/vgpu-proxmox/535.54.06.patch
  ./NVIDIA-Linux-x86_64-535.54.06-vgpu-kvm-custom.run --dkms

  reboot
  mdevctl types

  # get from nvidia-smi, drop 4 of the leading 0's
  export PCI_ADDRESS="0000:04:00.0"
  export DOMAIN=$(echo $PCI_ADDRESS |awk -F: '{print $1}')
  export BUS=$(echo $PCI_ADDRESS |awk -F: '{print $2}')
  export SLOT=$(echo $PCI_ADDRESS |awk -F: '{print $3}' |awk -F. '{print $1}')
  export FUNCTION=$(echo $PCI_ADDRESS |awk -F. '{print $2}')
  export TYPE="nvidia-18"

  /usr/lib/nvidia/sriov-manage -e $PCI_ADDRESS
  cd /sys/bus/pci/devices/$DOMAIN\:$BUS\:$SLOT.$FUNCTION/mdev_supported_types/

  # get names
  /usr/bin/cat nvidia-*/name

  # Get directory for desired card type
  # Q profiles can give you horrible performance in OpenGL applications/games. To fix that, switch to an equivalent A or B profile (for example GRID RTX6000-4B)
  # C profiles (for example GRID RTX6000-4C) only work on Linux, don't try using those on Windows, it will not work - at all.
  # A profiles (for example GRID RTX6000-4A) will NOT work on Linux, they only work on Windows.
  export CARD="GRID M60-2Q"
  export DIRECTORY=$(grep -l -w "$CARD" nvidia-*/name |awk -F/ '{print $1}')

  # Check how many instances are available
  /usr/bin/cat $DIRECTORY/available_instances
  /usr/bin/cat /sys/bus/pci/devices/0000:04:00.0/mdev_supported_types/nvidia-18/available_instances

  # Create a card
  export UUID=$(uuidgen)
  echo $UUID > $DIRECTORY/create
  echo "54c0879c-3ae9-47e1-ad7a-c7657ff8830f" > /sys/bus/pci/devices/0000:04:00.0/mdev_supported_types/nvidia-18/create

  # Verify its there
  ls /sys/bus/mdev/devices/$UUID
  ls /sys/bus/mdev/devices/54c0879c-3ae9-47e1-ad7a-c7657ff8830f

  # initialize the card
  sudo mdevctl define --auto --uuid $UUID
  sudo mdevctl define --auto --uuid 54c0879c-3ae9-47e1-ad7a-c7657ff8830f

  # verify mdev has it
  mdevctl list

  # in qemu add the gpu like this, also create a UUID for the VM
  -device vfio-pci,sysfsdev=/sys/bus/mdev/devices/$UUID \
  -uuid ebb10a6e-7ac9-49aa-af92-f56bb8c65893

  # Setup license Server
  WORKING_DIR=/opt/docker/fastapi-dls/cert
  mkdir -p $WORKING_DIR
  cd $WORKING_DIR

  # create instance private and public key for singing JWT's
  openssl genrsa -out $WORKING_DIR/instance.private.pem 2048 
  openssl rsa -in $WORKING_DIR/instance.private.pem -outform PEM -pubout -out $WORKING_DIR/instance.public.pem

  # create ssl certificate for integrated webserver (uvicorn) - because clients rely on ssl
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout  $WORKING_DIR/webserver.key -out $WORKING_DIR/webserver.crt

  # start license server
  docker run -e DLS_URL=<HOST IP> -e DLS_PORT=443 -p 443:443 -v $WORKING_DIR:/app/cert -v dls-db:/app/database collinwebdesigns/fastapi-dls:latest
  ```

  On the client
  ```bash
  wget https://f004.backblazeb2.com/file/buildstar-public-share/guest/NVIDIA-Linux-x86_64-535.54.03-grid.run
  sudo bash NVIDIA-Linux-x86_64-535.54.03-grid.run \
  --compat32-prefix=/usr \
  --compat32-libdir=lib32 \
  --dkms \
  

  cat << EOF > /etc/nvidia/gridd.conf
  ServerAddress="license-server-service.vgpu.svc.cluster.local"
  ServerPort=443
  FeatureType=0
  EOF

  wget --no-check-certificate -O /etc/nvidia/ClientConfigToken/client_configuration_token_$(date '+%d-%m-%Y-%H-%M-%S').tok https://license-server-service.vgpu.svc.cluster.local/-/client-token

  service nvidia-gridd restart
  nvidia-smi -q | grep "License"
  ```

## Guests

1. Install GPU Drivers (Skip if kuberntes node)

    <details>
      <summary>Debain Drivers</summary>
  
      ```bash
      apt-get install -y nvidia-driver \
      firmware-misc-nonfree \
      linux-headers-amd64 \
      gcc \
      linux-headers-`uname -r` \
      libvulkan1 \
      libglvnd-dev
      ```
  
    </details>


    <details>
      <summary>Ubuntu Drivers</summary>
  
      ```bash
      sudo apt-get install -y ubuntu-drivers-common \
        linux-headers-generic \
        gcc \
        kmod \
        make \
        pkg-config \
        libvulkan1 \
        libglvnd-dev
  
      #sudo ubuntu-drivers install nvidia:530
      wget https://us.download.nvidia.com/XFree86/Linux-x86_64/525.116.04/NVIDIA-Linux-x86_64-525.116.04.run
      ``` 
    
2. Install Container Toolkit

  - nvidia-container-tooklit: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
  - For Cuda drivers go here: https://developer.nvidia.com/cuda-downloads

    </details>
    
      <details>
      <summary>Ubuntu 22.04</summary>
  
      ```bash
      distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
  
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
 
      sudo apt-get update
      sudo apt-get install -y nvidia-container-toolkit
      sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
      sudo systemctl restart docker
      sudo sed -i 's/^#root/root/' /etc/nvidia-container-runtime/config.toml
      ```
    
    </details> 
    
    </details>
    
      <details>
      <summary>Debian 12</summary>
  
      ```bash
      distribution=debian11
  
      curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
 
      sudo apt-get update
      sudo apt-get install -y nvidia-container-toolkit
      sudo nvidia-ctk runtime configure --runtime=docker
      sudo systemctl restart docker
      sudo sed -i 's/^#root/root/' /etc/nvidia-container-runtime/config.toml
      ```
    
    </details> 
    
3. Test its workign with:

    ```bash
    sudo docker run --rm --runtime=nvidia --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi
    ```

## Kuberntes Node

1. install Python3.11 and brew

    ```bash
    wget -O setup.sh https://raw.githubusercontent.com/jessebot/onboardme/main/setup.sh
    . ./setup.sh 
    ```

2. install smol-k8s-lab

    ```bash
    pip3.11 install smol-k8s-lab
    ```

3. write setup config to `~/.config/smol-k8s-lab/config.yaml`

    ```bash
    mkdir -p ~/.config/smol-k8s-lab
    nvim ~/.config/smol-k8s-lab/config.yaml
    ```

    ```yaml
    domain:
      base: "cloudydev.net"
      argo_cd: "argocd"
      minio: "minio"
      minio_console: "console.minio"
    metallb_address_pool:
      - 10.0.2.16/32
      - 10.0.2.17/32
      - 10.0.2.18/32
    email: "admin@cloudydev.net"
    external_secrets:
      enabled: false
    log:
      level: "info"
    ```

    ```bash
    export KUBECONFIG=~/.config/kube/config
    ```

- Steam
  ```bash
  sudo dpkg --add-architecture i386
  sudo apt-get install steam-installer pciutils 
  ~/.steam/debian-installation/steam.sh
  ```

## Windows Guests

- Install Virtio drivers for disks at boot - [Link](https://linuxhint.com/install_virtio_drivers_kvm_qemu_windows_vm/)
- Install virtio-gpu drivers after first boot 
- Enable remote desktop - [Link](https://support.microsoft.com/en-us/windows/how-to-use-remote-desktop-5fe128d5-8fb1-7a23-3b8a-41e636865e8c#ID0EDD=Windows_10)
- Enable RDP GPU acceleration - [Link](https://www.leadergpu.com/articles/483-how-to-enable-gpu-rendering-for-microsoft-remote-desktop-on-leadergpu-servers)
- Enable 60 FPS for RDP - [Link](https://learn.microsoft.com/en-us/troubleshoot/windows-server/remote/frame-rate-limited-to-30-fps)
- Install GPU Drivers
- Disable Sleep/Suspend
- Activate licenses (optional)
- Enable Xbox system services - [Link](https://www.guidingtech.com/how-to-fix-xbox-app-wont-let-me-signin-on-windows/)
- Install Steam, EA App, Uplay, Epic Games Store, Xbox App, WSL

## How to run the ansible playbooks

Start the api server:

```bash
# Create a directory for a volume to store settings and a sqlite database
mkdir -p ~/.ara/server

# Start an API server with docker from the image on DockerHub:
docker run --name api-server --detach --tty \
  --volume ~/.ara/server:/opt/ara -p 8000:8000 \
  -e ARA_ALLOWED_HOSTS="['*']" \
  docker.io/recordsansible/ara-api:latest
```

build the ansible runner container

```bash
docker build -t ansible-runner .
```

Run the main playbook (insert your own user and password values)

```bash
docker run --platform linux/amd64 -it \
  -v $(pwd)/ansible:/ansible \
  -e ARA_API_SERVER="http://192.168.50.100:8000" \
  -e ARA_API_CLIENT=http \
  ansible-runner ansible-playbook playbooks/main-playbook.yaml \
  -i sample-inventory.yaml \
  --extra-vars "admin_password=ChangeMe!" \
  --extra-vars "admin_user=ChangeMe"
```

Install steam

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y steam-installer
export DISLAY=:0
steam
```
