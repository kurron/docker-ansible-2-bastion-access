#!/bin/bash

set -x

# Pulls the private SSH key from Ansible Vault.  All variables are expected
# to be available in the environment.

echo "VAULT_ADDR is ${VAULT_ADDR}"

# generate a temporary access token
export VAULT_TOKEN=$(vault write -field=token auth/approle/login role_id=${ROLE_ID} secret_id=${SECRET_ID})

# read the value from Vault, storing it in /tmp so ssh-add can read it
KEY_FILE=/tmp/private-key
vault read -field=value ${VAULT_PATH} > ${KEY_FILE}
chmod 0400 ${KEY_FILE}

# start the SSH agent
eval "$(ssh-agent)"

# add the key to the SSH agent (no time limit since we are running inside a container)
ssh-add ${KEY_FILE}

# prove that the key was installed
ssh-add -L

# Execute the Ansible plays
ANSIBLE="ansible-playbook --user ec2-user \
                          --inventory ${WORKERS} \
                          --verbose \
                          playbook.yml"
echo ${ANSIBLE}
${ANSIBLE}
