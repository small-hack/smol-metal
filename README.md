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
  EOF
  ```
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
  ```
  
## Initial Setup:

1. install basic dependancies

 - Apt Packages:
 
    ```bash
    sudo apt-get update && \
      sudo apt-get install -y wireguard \
      ssh-import-id \
      sudo \
      curl \
      netplan.io \
      apt-transport-https \
      ca-certificates \
      software-properties-common \
      netplan.io \
      git-extras \
      rsyslog \
      fail2ban \
      gpg
      
    sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq &&\
    sudo chmod +x /usr/bin/yq
    ```
  
 2. install docker
    
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
    sudo apt-get update && sudo apt-get install docker-ce
    ```

3. Setup the user

    ```bash
    sudo useradd -s /bin/bash -d /home/friend/ -m -G sudo friend
    sudo echo "friend ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    sudo -u friend ssh-import-id-gh cloudymax
    sudo usermod -a -G kvm friend
    sudo usermod -a -G docker friend
    passwd friend
    ```
    
4. Docker Compose
   
   ```bash
   mkdir -p ~/.docker/cli-plugins/
   curl -SL https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
   chmod +x ~/.docker/cli-plugins/docker-compose
   docker compose version
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
    
5. Setup Wireguard (Optional)

    <details>
      <summary>Click to expand</summary>

    ```bash
    sudo nano /etc/wireguard/wg0.conf

    sudo systemctl enable wg-quick@wg0
    sudo systemctl restart wg-quick@wg0
    ```
    </details>

6. Disable insecure ssh login options

    ```bash
    sudo wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/cloudymax/linux_notes/main/sshd_config

    sudo systemctl reload sshd
    ```

7. Setup PCI/IOMMU Passthrough (Optional)

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


## Guests

1. Install GPU Drivers (Skip if kuberntes node)

    <details>
      <summary>Debain Drivers</summary>
  
      ```bash
      apt-get install -y nvidia-driver \
      firmware-misc-nonfree \
      linux-headers-amd64 \
      gcc \
      linux-headers-`uname -r`
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
        libvulkan1
  
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
      sudo nvidia-ctk runtime configure --runtime=docker
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

4. Install HAproxy (if usiing SLIRP VM)

5. Nvidia gpu operator

```bash

```

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
