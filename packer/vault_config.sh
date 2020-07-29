#!/bin/env bash

# Unzip the vault binary and move it into place
cd /tmp
find . -maxdepth 1 -type f -name "vault*.zip" -exec unzip {} \;
if [[ -e /tmp/vault ]]; then
    # Move Vault into place
    sudo chown root:root /tmp/vault
    sudo mv /tmp/vault /usr/local/bin/
    vault -autocomplete-install
    sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault
    echo "Vault successfully unzipped and placed."
else
    echo "An error occurred unzipping Vault."
    exit 1
fi

# Move the vault config file into place
if [[ -e /tmp/vault.hcl ]]; then
    sudo mkdir --parents /etc/vault.d
    sudo useradd --system --home /etc/vault.d --shell /bin/false vault
    sudo cp /tmp/vault.hcl /etc/vault.d
    sudo chown --recursive vault:vault /etc/vault.d
    sudo chmod 640 /etc/vault.d/vault.hcl
    echo "Vault config file moved to /etc/vault.d"
else
    echo "Vault config file does not exist."
    exit 2
fi

# Move the vault service file into place
if [[ -e /tmp/vault.service ]]; then
    sudo chown root:root /tmp/vault.service
    sudo mv /tmp/vault.service /etc/systemd/system
    echo "Vault systemd service file moved into place." 
else
    echo "Vault systemd service file missing."
    exit 3
fi

# Enable and start vault service
sudo systemctl enable vault
sudo systemctl start vault
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc
echo "Vault config complete."
