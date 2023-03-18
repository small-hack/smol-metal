# Create a directory for a volume to store settings and a sqlite database
mkdir -p ~/.ara/server

# Start an API server with docker from the image on DockerHub:
docker run --name api-server --detach --tty \
  --volume ~/.ara/server:/opt/ara -p 8000:8000 \
  docker.io/recordsansible/ara-api:latest

# build the runner
docker build -t ansible-runner .

# download vm script and congif file
mkdir -p test
wget -O test/config.yaml https://raw.githubusercontent.com/cloudymax/Scrap-Metal/main/virtual-machines/config.yaml
wget -O vm.sh https://raw.githubusercontent.com/cloudymax/Scrap-Metal/main/virtual-machines/vm.sh

# Create the vm 
bash vm.sh deps
time bash vm.sh create-cloud-vm test

# Run a playbook
docker run --platform linux/amd64 -it \
  -v $(pwd)/ansible:/ansible \
  -v $(pwd)/test/friend:/id_rsa \
  -e ARA_API_SERVER="http://192.168.50.100:8000" \
  -e ARA_API_CLIENT=http \
  ansible-runner ansible-playbook playbooks/main-playbook.yaml \
  -i sample-inventory.yaml \
  --extra-vars="admin_password=password" \
  --extra-vars="admin_user=friend" \
  --extra-vars="ansible_user=testadmin" \
  --extra-vars="ansible_ssh_private_key_file=/id_rsa" \
  --extra-vars="ansible_ssh_user=testadmin"
