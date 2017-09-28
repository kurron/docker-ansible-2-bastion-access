FROM ubuntu:16.04

MAINTAINER Ron Kurr <kurr@kurron.org>

# have Ansible examine the container, by default
CMD ["/usr/bin/ansible", "all", "--inventory=localhost,", "--verbose", "--connection=local", "-m setup"]

# ---- watch your layers and put likely mutating operations here -----

RUN apt-get update --yes && \
    apt-get install --yes software-properties-common openssh-client curl && \
    apt-add-repository --yes ppa:ansible/ansible && \
    apt-get update --yes && \
    apt-get install --yes ansible && \
    apt-get purge --yes
