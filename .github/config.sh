#!/bin/bash

# Install .NET
sudo apt-get update
sudo apt-get install -y dotnet-sdk-5.0
sudo apt-get install -y dotnet-sdk-7.0

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


curl -o vstsagent.tar.gz https://vstsagentpackageurl
tar zxvf vstsagent.tar.gz
./config.sh --unattended --url $URL --auth PAT --token $TOKEN --pool Default --agent $AGENT_NAME

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

./run
