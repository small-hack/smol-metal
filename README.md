# Server-Configuration

Some Ansible server-management helpers for resources that cant be managed/boot-strapped via Cloud-Init.

## Resources

- [Wireguard - the Fast, Modern, Secure VPN Tunnel](https://www.wireguard.com/)
- [How To Set Up WireGuard on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04)
- [How To Set Up a Firewall with UFW on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-22-04)
- [UFW Essentials: Common Firewall Rules and Commands](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)
- [Fail2ban Wiki](https://github.com/fail2ban/fail2ban/wiki)
- [How To Protect SSH with Fail2Ban on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-22-04)
- [Importing user SSH keys from Github](https://github.com/dustinkirkland/ssh-import-id)
- [Hashing passwords for use with cloud-init](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [Setting up Prometheus node exporter](https://prometheus.io/docs/guides/node-exporter/)
- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Loki Install](https://grafana.com/docs/loki/latest/installation/?pg=oss-loki&plcmt=resources)
- [Install Grafana](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

## Pre-flight checks for Debian on Bare-Metal

We want to do all this over wireguard and since we dont have an automated
debian install we need to prep the system for use with ansible manually.

## As Sudo:

1. Fix apt sources

```bash
cat << EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free
deb-src http://deb.debian.org/debian bookworm main contrib non-free

deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free

deb http://deb.debian.org/debian bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free
EOF
```

2. install deps

```bash
# Package Choice Justifications
# sudo - a user with passwordless sudo for automations
# ssh-import-id - ssh key imports
# wireguard - setup vpn (get keys from bitwarden)
# curl - for onboardme
# nvidia-driver firmware-misc-nonfree linux-headers-amd64 are for GPU

apt-get update && apt-get install -y wireguard \
  ssh-import-id \
  sudo \
  curl \
  nvidia-driver \
  firmware-misc-nonfree \
  linux-headers-amd64 \
  docker.io \
  netplan.io
```

3. add passwordless sudo
```bash
echo "friend ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
```

4. bridge the network adapter

```bash
cat << EOF > /etc/netplan/99-bridge.yaml
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
EOF

sudo netplan --debug generate
sudo netplan --debug apply
```

5. Set grub to enable iommu

```bash
cat << EOF > /tmp/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet preempt=voluntary iommu=pt amd_iommu=on intel_iommu=on"
GRUB_CMDLINE_LINUX=""
EOF

sudo mv /tmp/grub /etc/default/grub
sudo update-grub
```

## As User:

```bash
ssh-import-id-gh cloudymax
```

```bash
sudo nano /etc/wireguard/wg0.conf

sudo systemctl enable wg-quick@wg0

sudo systemctl restart wg-quick@wg0
```

```bash
sudo wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/cloudymax/linux_notes/main/sshd_config

sudo systemctl reload sshd
```

## How to run the ansible playbooks

- populate ansible/inventory

- Run the playbook

```bash
# Create a directory for a volume to store settings and a sqlite database
mkdir -p ~/.ara/server

# Start an API server with docker from the image on DockerHub:
docker run --name api-server --detach --tty \
  --volume ~/.ara/server:/opt/ara -p 8000:8000 \
  docker.io/recordsansible/ara-api:latest

# build the runner
docker build -t ansible-runner .

# Run a playbook
docker run --platform linux/amd64 -it \
  -v $(pwd)/ansible:/ansible \
  docker run -it -v $(pwd)/ansible:/ansible \
  ansible-runner ansible-playbook playbooks/install_onboardme.yaml \
  -i sample-inventory.yaml
```

## Playbooks

1. main-playbook.yaml
  - setus up users, ssh keys, basic apt packagaes, apt-update/upgrade prometheus node-exporter

2. install_brew.yaml
  - clones the brew repo, installs it and sets the env vars correctly

3. install_onboardme.yaml
  - installs onboardme
