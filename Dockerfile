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

RUN pip3 --no-cache-dir install --upgrade pip \
  && pip3 install ansible-core ansible-cmdb \
  && pip3 install --user ansible ara

ENV BW_CLI_VERSION=2023.1.0

RUN apt update && \
  apt install -y wget unzip \
  && wget https://github.com/bitwarden/clients/releases/download/cli-v${BW_CLI_VERSION}/bw-linux-${BW_CLI_VERSION}.zip \
  && unzip bw-linux-${BW_CLI_VERSION}.zip \
  && chmod +x bw \
  && mv bw /usr/local/bin/bw \
  && rm -rfv *.zip \
  && rm -rf /var/lib/apt/lists/*
    
WORKDIR /ansible

RUN ansible-galaxy collection install \
  community.general \
  community.crypto \
  ansible.posix

ENV ANSIBLE_CALLBACK_PLUGINS="/root/.local/lib/python3.10/site-packages/ara/plugins/callback"

# create a user for non-root operation
ARG USER="user"
RUN useradd -ms /bin/bash $USER && \
        mkdir -p /home/$USER/.local/bin && \
        mkdir -p /home/$USER/.local/lib && \
        chown -R $USER:$USER /home/$USER/

# Swap to user account
USER $USER
WORKDIR /home/$USER/
