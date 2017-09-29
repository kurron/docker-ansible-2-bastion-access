#!/bin/bash

FOO="-F ssh-config.ini"
CMD="ansible --user ec2-user \
             --inventory-file hosts.ini \
             --verbose \
             -m ping all"

echo ${CMD}
${CMD}
