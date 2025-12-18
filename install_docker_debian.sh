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

# Helper function to log messages (handles sudo for /var/log)
log_msg() {
    echo "$*"
    echo "$*" | $SUDO tee -a "$LOGFILE" > /dev/null
}

# Function to run commands and log output
run_command() {
    log_msg "Running: $*"
    $SUDO "$@" 2>&1 | $SUDO tee -a "$LOGFILE" > /dev/null
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_msg "Error running: $*"
    fi
}


# Get Debian version codename and version ID
. /etc/os-release
DEBIAN_CODENAME="$VERSION_CODENAME"
DEBIAN_VERSION_ID="${VERSION_ID:-0}"

log_msg "Detected Debian: $DEBIAN_CODENAME (version $DEBIAN_VERSION_ID)"

# Determine if we should use DEB822 format (Debian 13/Trixie and later)
use_deb822_format() {
    # Trixie is Debian 13, use DEB822 format for version 13+
    # Also check codename in case VERSION_ID is not set
    if [ "$DEBIAN_VERSION_ID" -ge 13 ] 2>/dev/null || [ "$DEBIAN_CODENAME" = "trixie" ]; then
        return 0
    fi
    return 1
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
if use_deb822_format; then
    log_msg "Using DEB822 format for apt sources (Trixie+)"
    # Remove old .list file if it exists
    [ -f /etc/apt/sources.list.d/docker.list ] && run_command rm /etc/apt/sources.list.d/docker.list
    # Use DEB822 format for Trixie and later
    $SUDO tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $DEBIAN_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
else
    log_msg "Using traditional format for apt sources (pre-Trixie)"
    # Remove new .sources file if it exists
    [ -f /etc/apt/sources.list.d/docker.sources ] && run_command rm /etc/apt/sources.list.d/docker.sources
    # Use traditional format for older versions
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $DEBIAN_CODENAME stable" | \
      $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

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
