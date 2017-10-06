#!/bin/bash

# Environment variables required by the AWS CLI
BASTION_ADDRESS=${BASTION_ADDRESS:-52.36.175.254}
DOCKER_ADDRESSES=${DOCKER_ADDRESSES:-10.0.1.194,10.0.3.253}

# Environment variables needed to map the Docker user to the user's Environment
SSH_GROUP_ID=${SSH_GROUP_ID:-$(cut -d: -f3 < <(getent group ssh))}
USER_ID=${USER_ID:-$(id -u $(whoami))}
GROUP_ID=${GROUP_ID:-$(id -g $(whoami))}
HOME_DIR=${HOME_DIR:-$(cut -d: -f6 < <(getent passwd ${USER_ID}))}

# Environment variables needed to contact Hashicorp's Vault
VAULT_ADDR=${VAULT_ADDR:-http://192.168.254.90:8200}
ROLE_ID=${ROLE_ID:-CHANGEME}
SECRET_ID=${SECRET_ID:-CHANGEME}
VAULT_PATH=${VAULT_PATH:-CHANGEME}

function runContainer() {
  local CMD="docker run --net host \
                  --add-host bastion:${BASTION_ADDRESS} \
                  --hostname inside-docker \
                  --env HOME=${HOME_DIR} \
                  --env ANSIBLE_CONFIG=/tmp/ansible.cfg \
                  --env VAULT_ADDR=${VAULT_ADDR} \
                  --env ROLE_ID=${ROLE_ID} \
                  --env SECRET_ID=${SECRET_ID} \
                  --env VAULT_PATH=${VAULT_PATH} \
                  --env WORKERS=${DOCKER_ADDRESSES} \
                  --interactive \
                  --name deployer-test \
                  --rm \
                  --tty \
                  --user=${USER_ID}:${GROUP_ID} \
                  --volume $(pwd):$(pwd) \
                  --volume ${HOME_DIR}:${HOME_DIR} \
                  --volume /etc/passwd:/etc/passwd \
                  --volume /etc/group:/etc/group \
                  --workdir $(pwd) \
                  dockeransible2bastionaccess_deployer:latest bash"
  echo $CMD
  $CMD
}

runContainer
