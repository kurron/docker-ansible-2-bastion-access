#!/bin/bash

# Any arguments provided to this script will be the command run inside the container.
# This to try:
#   * ansible --version
#   * ansible all --inventory='localhost,' --connection=local -m ping


PROJECT=${1:-Weapon-X}
ENVIRONMENT=${2:-development}
REGION=${3:-us-west-2}
PRIVATE_SSH_KEY=${4:-bastion}

function determineBastionAddress() {
  local STATE_FILTER=Name=instance-state-name,Values=running
  local PROJECT_FILTER=Name=tag:Project,Values=$2
  local ENVIRONMENT_FILTER=Name=tag:Environment,Values=$3
  local DUTY_FILTER=Name=tag:Duty,Values=$4

  local CMD="aws --profile qa \
                 --region $1 \
                 ec2 describe-instances \
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
  local PROJECT_FILTER=Name=tag:Project,Values=$2
  local ENVIRONMENT_FILTER=Name=tag:Environment,Values=$3
  local DUTY_FILTER=Name=tag:Duty,Values=$4

  local CMD="aws --profile qa \
                 --region $1 \
                 ec2 describe-instances \
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

function addKeyToAgent() {
  local ADD_KEY="ssh-add ${PRIVATE_SSH_KEY}"
  echo ${ADD_KEY}
  ${ADD_KEY}
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
                  --env SSH_AUTH_SOCK=${SSH_AUTH_SOCK} \
                  --interactive \
                  --name deployer-test \
                  --rm \
                  --tty \
                  --user=${USER_ID}:${GROUP_ID} \
                  --volume ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK} \
                  --volume $(pwd):$(pwd) \
                  --volume ${HOME_DIR}:${HOME_DIR} \
                  --volume /etc/passwd:/etc/passwd \
                  --volume /etc/group:/etc/group \
                  --workdir $(pwd) \
                  dockeransible2bastionaccess_deployer:latest ${ANSIBLE}"
  echo $CMD
  $CMD
}

determineBastionAddress ${REGION} ${PROJECT} ${ENVIRONMENT} Bastion
determineDockerAddresses ${REGION} ${PROJECT} ${ENVIRONMENT} Docker
addKeyToAgent
runContainer
