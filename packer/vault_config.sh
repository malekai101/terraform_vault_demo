#!/bin/env bash

# Unzip the vault binary and move it into place
cd /tmp
find . -maxdepth 1 -type f -name "/tmp/vault*.zip" -exec unzip {} \;
if [[ -e /tmp/vault ]] then;
    echo "Vault successfully unzipped."
    # Move Vault into place
    sudo chown root:root /tmp/vault
    sudo mv /tmp/vault /usr/local/bin/
    vault --verison
else
    echo "An error occurred unzipping Vault."
    exit 1
fi

# Move the vault config file into place
if [[ -e /tmp/vault.hcl ]]; then
    sudo mkdir --parents /etc/vault.d
    sudo cp /tmp/vault.hcl /etc/vault.d
    sudo chown --recursive vault:vault /etc/vault.d
    sudo chmod 640 /etc/vault.d/vault.hcl
    echo "Vault config file moved to /etc/vault.d"
else
    echo "Vault config file does not exist."
    exit 2
fi

# Create users for vault and set some system stuff
vault -autocomplete-install
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
sudo useradd --system --home /etc/vault.d --shell /bin/false vault


# Create the directory structure for the vault config

# Move the vault service file into place
# Enable vault service
# Start vault service