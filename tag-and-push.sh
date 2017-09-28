#!/bin/bash

# use the time as a tag
UNIXTIME=$(date +%s)

# docker tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]
docker tag dockeransible2bastionaccess_deployer:latest kurron/docker-ansible:latest
docker tag dockeransible2bastionaccess_deployer:latest kurron/docker-ansible:${UNIXTIME}
docker images

# Usage:  docker push [OPTIONS] NAME[:TAG]
docker push kurron/docker-ansible:latest
docker push kurron/docker-ansible:${UNIXTIME}
