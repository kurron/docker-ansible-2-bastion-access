#!/bin/bash

# Any arguments provided to this script will be the command run inside the container.
# This to try:
#   * ansible --version
#   * ansible all --inventory='localhost,' --connection=local -m ping

SSH_GROUP_ID=$(cut -d: -f3 < <(getent group ssh))
USER_ID=$(id -u $(whoami))
GROUP_ID=$(id -g $(whoami))
WORK_AREA=/work-area
HOME_DIR=$(cut -d: -f6 < <(getent passwd ${USER_ID}))

PROJECT=${1:-Weapon-X}
ENVIRONMENT=${2:-development}
REGION=${3:-us-west-2}

STATE_FILTER=Name=instance-state-name,Values=running
#PROJECT_FILTER=Name=tag:Project,Values=${PROJECT}
PROJECT_FILTER=Name=tag:Project,Values=Weapon-X
ENVIRONMENT_FILTER=Name=tag:Environment,Values=${ENVIRONMENT}
NAME_FILTER=Name=tag:Name,Values=Bastion

EC2_CMD="aws --profile qa \
             --region ${REGION} \
             ec2 describe-instances \
             --filters ${STATE_FILTER} \
             --filters ${PROJECT_FILTER} \
             --filters ${ENVIRONMENT_FILTER} \
             --filters ${NAME_FILTER} \
             --query Reservations[*].Instances[*].[PublicIpAddress] \
             --output text"
echo ${EC2_CMD}
BASTION=$(${EC2_CMD})
echo ${BASTION}

ADD_KEY="ssh-add bastion"
echo ${ADD_KEY}
${ADD_KEY}

CMD="docker run --net host \
                --add-host bastion:${BASTION}\
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
                dockeransible2bastionaccess_deployer:latest $*"
echo $CMD
$CMD
