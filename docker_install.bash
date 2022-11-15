#!/bin/bash
dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
dnf -y install yum-utils
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf remove runc
dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
dnf list docker-ce --showduplicates | sort -r
systemctl status docker
systemctl enable docker
systemctl restart docker
docker run hello-world
