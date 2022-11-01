# vps-configuration

Server management resources for resources that cant be managed/boot-strapped via Cloud-Init.


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

- Run the playbook 

```bash
docker run --platform linux/amd64 -it \
  -v $(pwd)/ansible:/ansible \
  -w /ansible \
  runner ansible-playbook main-playbook.yaml \
  -i inventory.yaml \
  --extra-vars \
  "max_password='$(bw get password max-hetzner)' \
   jesse_password='$(bw get password jesse-hetzner-ssh-encrypted)'"

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

## Hosts

### Hetzner

- [Management Console](https://robot.hetzner.com/server) - Credentials are in bitwarden

- IP: 176.9.44.19

### Local Metal

- IP: 192.168.50.100

## Specs

```bash
-------------------- A Bench.sh Script By Teddysun -------------------
 Version            : v2022-06-01
 Usage              : wget -qO- bench.sh | bash
----------------------------------------------------------------------
 CPU Model          : 12th Gen Intel(R) Core(TM) i5-12500
 CPU Cores          : 12 @ 3889.649 MHz
 CPU Cache          : 18432 KB
 AES-NI             : Enabled
 VM-x/AMD-V         : Enabled
 Total Disk         : 436.7 GB (3.4 GB Used)
 Total Mem          : 62.6 GB (330.4 MB Used)
 Total Swap         : 32.0 GB (0 Used)
 System uptime      : 0 days, 8 hour 2 min
 Load average       : 0.07, 0.05, 0.01
 OS                 : Ubuntu 22.04.1 LTS
 Arch               : x86_64 (64 Bit)
 Kernel             : 6.1.0-060100rc1-generic
 TCP CC             : cubic
 Virtualization     : Dedicated
 Organization       : AS24940 Hetzner Online GmbH
 Location           : Falkenstein / DE
 Region             : Saxony
----------------------------------------------------------------------
 I/O Speed(1st run) : 806 MB/s
 I/O Speed(2nd run) : 1.2 GB/s
 I/O Speed(3rd run) : 1.8 GB/s
 I/O Speed(average) : 1292.7 MB/s
----------------------------------------------------------------------
 Node Name        Upload Speed      Download Speed      Latency     
 Speedtest.net    935.04 Mbps       924.83 Mbps         3.19 ms     
----------------------------------------------------------------------
 Finished in        : 16 sec
 Timestamp          : 2022-10-26 18:17:39 UTC
----------------------------------------------------------------------
```
