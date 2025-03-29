#!/bin/bash


LOGFILE="/var/log/myscript.log"

# check if binary is installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}


# Check if the current user is root
if [ "$EUID" -ne 0 ]; then
# Check if sudo is installed
    if ! command_exists sudo; then
        echo "Error: 'sudo' is not installed on this system."
        echo "Please install sudo and rerun the script."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi


# Function to run commands and log output
run_command() {
    echo "Running: $*" | tee -a "$LOGFILE"
    $SUDO "$@" >>"$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        echo "Error running: $*" | tee -a "$LOGFILE"
    fi
}



# Ground cleaning uninstalling unofficial packages
# ref, https://docs.docker.com/engine/install/debian/
#
#  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
run_command apt-get update
run_command apt-get -y install ca-certificates curl
run_command install -m 0755 -d /etc/apt/keyrings
run_command curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
run_command chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  run_command tee /etc/apt/sources.list.d/docker.list > /dev/null
run_command apt-get update

# install the latest Docker packages
run_command apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# post install
# ref, https://docs.docker.com/engine/install/linux-postinstall/
# test the docker install
# sudo docker run hello-world

# create the docker group
#sudo groupadd docker

# add the current user to the docker group
# sudo usermod -aG docker $USER
# newgrp docker

# test docker again under current user
# docker run hello-world
