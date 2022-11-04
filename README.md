# vps-configuration

Some Ansible server-management helpers for resources that cant be managed/boot-strapped via Cloud-Init.


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

