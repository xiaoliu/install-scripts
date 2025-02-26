#!/bin/bash

# ground cleaning uninstalling unofficial packages
# ref, https://docs.docker.com/engine/install/debian/
#
#  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install the latest Docker packages
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# post install
# ref, https://docs.docker.com/engine/install/linux-postinstall/
# test the docker install
sudo docker run hello-world

# create the docker group
#sudo groupadd docker

# add the current user to the docker group
sudo usermod -aG docker $USER
newgrp docker

# test docker again under current user
docker run hello-world
