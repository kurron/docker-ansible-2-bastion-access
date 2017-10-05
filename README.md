# Overview
This project is a simple Docker container with [Ansible](https://www.ansible.com/)
and [Vault](https://www.vaultproject.io/) installed.  This container
ties together several concepts, making Ansible deployment easier for AWS VPCs
that hide EC2 instances behind a Bastion server.

The steps carried out are:

1. use the AWS CLI to determine the address of the Bastion server
1. use the AWS CLI to determine the addresses of the Docker servers
1. fire up a container, feeding it the discovered addresses
1. inside the container, spin up ssh-agent
1. inside the container, consult Terraform Vault for the private SSH key
1. inside the container, add the key to the ssh-agent
1. inside the container, run the Ansible playbook, tunneling SSH traffic through the Bastion server

# Guidebook
Details about this project are contained in the [guidebook](guidebook/guidebook.md)
and should be considered mandatory reading prior to contributing to this project.

# Prerequisites
* a working [Docker](http://docker.io) engine
* a working [Docker Compose](http://docker.io) installation
* a working [AWS CLI](https://aws.amazon.com/cli/) installation

# Building
Type `./build.sh` to build the image.

# Installation
Docker will automatically install the newly built image into the cache.

# Tips and Tricks

## Launching The Image
Use `./test.sh` to exercise the image.

# Troubleshooting

# Contributing

# License and Credits
This project is licensed under the [Apache License Version 2.0, January 2004](http://www.apache.org/licenses/).

# List of Changes
