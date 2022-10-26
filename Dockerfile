FROM ubuntu:latest as ansible

ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_VAULT_PASSWORD_FILE="{{CWD}}/.vault_pass"
ENV ANSIBLE_NOCOWS=1 

RUN apt-get update \
  && apt-get install -y python3-pip python3-dev sshpass tmux \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 --no-cache-dir install --upgrade pip \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install ansible-core ansible-cmdb

RUN mkdir /ansible
WORKDIR /ansible

RUN ansible-galaxy collection install community.general community.crypto ansible.posix
