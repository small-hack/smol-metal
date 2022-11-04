FROM ubuntu:latest as ansible

ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_VAULT_PASSWORD_FILE="{{CWD}}/.vault_pass"
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
  && pip3 install --user ansible "ara[server]"

WORKDIR /ansible

RUN ansible-galaxy collection install \
  community.general \
  community.crypto \
  ansible.posix \
  && export ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)" \
  && export ARA_ALLOWED_HOSTS="[*]"

#RUN ara-manage runserver 0.0.0.0:8000 
