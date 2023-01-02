FROM ubuntu:latest as ansible

ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_NOCOWS=1
ENV PATH="$PATH:/home/ansible/.local/bin"

RUN mkdir -p /ansible \
  && useradd -ms /bin/bash ansible \
  && apt-get update \
  && apt-get install -y python3-pip python3-dev sshpass tmux \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && rm -rf /var/lib/apt/lists/*

#USER ansible

RUN pip3 --no-cache-dir install --upgrade pip \
  && pip3 install ansible-core ansible-cmdb \
  && pip3 install --user ansible ara

WORKDIR /ansible

RUN ansible-galaxy collection install \
  community.general \
  community.crypto \
  ansible.posix

ENV ANSIBLE_CALLBACK_PLUGINS="/root/.local/lib/python3.10/site-packages/ara/plugins/callback"
ENV ARA_API_CLIENT=http
ENV ARA_API_SERVER="http://192.168.50.129:80"
