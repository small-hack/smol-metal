# VPS-Configuration

Some Ansible server-management helpers for resources that cant be managed/boot-strapped via Cloud-Init.

This repo can manage your:

- Wireguard VPN client/server install
- Firewall Rules via UFW
- Intrusion prevention via Fail2Ban
- Users accounts, passwords, and ssh-keys
- Apt and Brew packaages
- Metrics exporting from Prometheus
- Log exporting from Promtail (WiP)
- Log Aggregation via Loki (WiP)
- Dashboards via Grafana

## Reasources

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

## ToDo:

- make prometheus scrape targets populate from a list
- add some choice prometheus alert rules
- get alert manager working w/ slack & discord
- add some provisioned data-sources for grafana
- add some provisioned dashboards for the node exporter
- add Loki for log aggregation
- add promtail for log exporting
- add SSL to prometheus node exporter

## How to run the ansible playbooks

- Log in to bitwarden cli
- Unlock the vault
- Get the user-name and password from bitwarden

```bash
bw get username hetzner-vps
bw get password hetzner-vps
```

- populate ansible/inventory 

- encrypt the inventory file

- create and populate ansible/.vault_pass

- add users you want to manage to the main-playbook.yaml

- pass the user's names and passwords as extravars (example below)

- Run the playbook 

```bash
docker run --platform linux/amd64 -it \
  -v $(pwd)/ansible:/ansible \
  -w /ansible \
  runner ansible-playbook main-playbook.yaml \
  -i inventory.yaml \
  --extra-vars \
  "user0_password='$(bw get password user0)' \
   user1_password='$(bw get password user1)'"

```

## Playbooks

1. main-playbook.yaml
  - setus up users, ssh keys, basic apt packagaes, apt-update/upgrade, fail2ban jails, prometheus node-exporter, and uses scrap-metal to set the cpu to performance mode
  
2. brew_install.yaml
  - clones the brew repo, installs it and sets the env vars correctly
  
3. firewall
  - parses approved-ips.yaml and adds those items to a uwf firewall

4. monitoring-playbook
  - sets up a prometheus and grafana server using docker-compose on the target system

