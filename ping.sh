#!/bin/bash

INVENTORY="${1:-10.0.1.234,10.0.3.181}"

CMD="ansible --user ec2-user \
             --inventory ${INVENTORY} \
             --verbose \
             -m ping all"

echo ${CMD}
${CMD}
