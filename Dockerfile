FROM ubuntu:16.04

MAINTAINER Ron Kurr <kurr@kurron.org>

# have Ansible examine the container, by default
CMD ["/usr/bin/ansible", "all", "--inventory=localhost,", "--verbose", "--connection=local", "-m setup"]

# ---- watch your layers and put likely mutating operations here -----

COPY ansible/ansible.cfg /tmp/ansible.cfg
COPY ansible/ssh-config.ini /tmp/ssh-config.ini

ADD https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip /tmp/vault.zip

RUN apt-get update --yes && \
    apt-get install --yes software-properties-common openssh-client curl unzip && \
    apt-add-repository --yes ppa:ansible/ansible && \
    apt-get update --yes && \
    apt-get install --yes ansible python-pip && \
    apt-get purge --yes && \
    unzip /tmp/vault.zip -d /usr/local/bin && \
    chmod a+w /usr/local/bin/vault && \
    pip install awscli
