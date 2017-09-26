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

CMD="docker run --net host \
                --hostname inside-docker \
                --env HOME=${HOME_DIR} \
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
                dockeransible2bastionaccess_deployer:latest $*"
echo $CMD
$CMD
