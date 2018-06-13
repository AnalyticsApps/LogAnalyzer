#!/bin/bash

# Update the Systems
yum update -y

repo="[dockerrepo]\nname=Docker Repository\nbaseurl=https://yum.dockerproject.org/repo/main/centos/7/\nenabled=1\ngpgcheck=1\ngpgkey=https://yum.dockerproject.org/gpg\n"

echo -e $repo > /etc/yum.repos.d/docker.repo

yum install docker-engine -y

mkdir -p /var/lib/docker/devicemapper/devicemapper

dd if=/dev/zero of=/var/lib/docker/devicemapper/devicemapper/data bs=1G count=0 seek=110

dockerd --storage-opt dm.basesize=20G

systemctl start docker



#service docker start

#docker run hello-world
