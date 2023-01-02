# VPS-Configuration

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

- Need a user with passwordless sudo
- need ssh key imported
- need wireguard setup (get keys from bitwarden)
- need sudo installed

```bash

su

cat > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free
deb-src http://deb.debian.org/debian bookworm main contrib non-free

deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free
deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free

deb http://deb.debian.org/debian bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free

# press enter, then ctrl + d

apt-get update

apt-get install wireguard ssh-import-id sudo

echo "max ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ssh-import-id-gh cloudymax

sudo nano /etc/wireguard/wg0.conf

sudo systemctl enable wg-quick@wg0

sudo systemctl restart wg-quick@wg0

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
