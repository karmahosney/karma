#!/bin/bash
cd /etc/yum.repos.d/
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo
dnf -y update
dnf -y group install "Development Tools"
dnf -y install kernel-devel
dnf -y install VirtualBox-7.0.x86_64
