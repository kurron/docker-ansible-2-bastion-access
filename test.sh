#!/bin/bash

# Environment variables required by the AWS CLI
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-CHANGEME}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-CHANGEME}

# Environment variables used to locate the proper EC2 instances
PROJECT=${PROJECT:-Weapon-X}
ENVIRONMENT=${ENVIRONMENT:-development}

# Environment variables used to access Hashicorp Vault, which holds the private SSH key
VAULT_ADDR=${VAULT_ADDR:-http://192.168.254.90:8200}
ROLE_ID=${ROLE_ID:-ab30c420-3f48-60e3-b45e-07a672aa4860}
SECRET_ID=${SECRET_ID:-0fb79713-0c1b-edd2-6d60-b6714da074d2}
VAULT_PATH=${VAULT_PATH:-secret/build/ssh/slurpe}

function determineBastionAddress() {
  local STATE_FILTER=Name=instance-state-name,Values=running
  local PROJECT_FILTER=Name=tag:Project,Values=${PROJECT}
  local ENVIRONMENT_FILTER=Name=tag:Environment,Values=${ENVIRONMENT}
  local DUTY_FILTER=Name=tag:Duty,Values=$1

  local CMD="aws ec2 describe-instances \
                 --filters ${STATE_FILTER} \
                 --filters ${PROJECT_FILTER} \
                 --filters ${ENVIRONMENT_FILTER} \
                 --filters ${DUTY_FILTER} \
                 --query Reservations[0].Instances[*].[PublicIpAddress] \
                 --output text"
  echo ${CMD}
  BASTION=$(${CMD})
  echo "Bastion IP address is ${BASTION}"

}

function determineDockerAddresses() {
  local STATE_FILTER=Name=instance-state-name,Values=running
  local PROJECT_FILTER=Name=tag:Project,Values=${PROJECT}
  local ENVIRONMENT_FILTER=Name=tag:Environment,Values=${ENVIRONMENT}
  local DUTY_FILTER=Name=tag:Duty,Values=$1

  local CMD="aws ec2 describe-instances \
                 --filters ${STATE_FILTER} \
                 --filters ${PROJECT_FILTER} \
                 --filters ${ENVIRONMENT_FILTER} \
                 --filters ${DUTY_FILTER} \
                 --query Reservations[*].Instances[*].[PrivateIpAddress] \
                 --output text"

  echo ${CMD}
  local IDS=$(${CMD})
  echo ${IDS}
  WORKERS=$(echo ${IDS} | sed -e "s/ /,/g")
  echo "Docker addresses are ${WORKERS}"
}

function runContainer() {
  local SSH_GROUP_ID=$(cut -d: -f3 < <(getent group ssh))
  local USER_ID=$(id -u $(whoami))
  local GROUP_ID=$(id -g $(whoami))
  local WORK_AREA=/work-area
  local HOME_DIR=$(cut -d: -f6 < <(getent passwd ${USER_ID}))

  ANSIBLE="ansible-playbook --user ec2-user \
                            --inventory ${WORKERS} \
                            --verbose \
                            playbook.yml"

  echo ${ANSIBLE}

  local CMD="docker run --net host \
                  --add-host bastion:${BASTION} \
                  --hostname inside-docker \
                  --env HOME=${HOME_DIR} \
                  --env ANSIBLE_CONFIG=/tmp/ansible.cfg \
                  --env VAULT_ADDR=${VAULT_ADDR} \
                  --env ROLE_ID=${ROLE_ID} \
                  --env SECRET_ID=${SECRET_ID} \
                  --env VAULT_PATH=${VAULT_PATH} \
                  --env WORKERS=${WORKERS} \
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
                  dockeransible2bastionaccess_deployer:latest ./deploy-docker-containers.sh"
  echo $CMD
  $CMD
}

determineBastionAddress Bastion
determineDockerAddresses Docker
runContainer
