#!/bin/bash

# url for github api endpoint
base_api_url="https://api.github.com"

# Username or Org name
owner=$1

# Name of the repository to create a runner for
repo=$2

# Access token
token=$3

# Runner platform
runner_plat=linux

# Get a authorized token for your repo/org
export RUNNER_TOKEN=$(curl -s -X POST ${base_api_url}/repos/${owner}/${repo}/actions/runners/registration-token -H "accept: application/vnd.github.everest-preview+json" -H "authorization: token ${token}" | jq -r '.token')

# Find the latest version of the runner software
latest_version_label=$(curl -s -X GET 'https://api.github.com/repos/actions/runner/releases/latest' | jq -r '.tag_name')
latest_version=$(echo ${latest_version_label:1})

# Assemble the string-value for the runner application archive
runner_file="actions-runner-${runner_plat}-x64-${latest_version}.tar.gz"

# Assemble the download URL
runner_url="https://github.com/actions/runner/releases/download/${latest_version_label}/${runner_file}"

# Download and extract the archive
wget -O ${runner_file} ${runner_url}
tar xzf "./${runner_file}"

# Install and configure the application without prompting for user-input
./config.sh --url https://github.com/${owner}/${repo} \
  --token ${RUNNER_TOKEN} \
  --unattended \
  --ephemeral

./svc.sh install
./svc.sh start
./svc.sh status
