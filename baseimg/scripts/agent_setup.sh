#!/bin/bash

printf "\n Preparing the environment \n"
systemctl enable ntpd.service && systemctl start ntpd.service
timedatectl set-timezone America/New_York
echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo -e "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then \n    echo never > /sys/kernel/mm/transparent_hugepage/enabled\nfi" >> /etc/rc.local

# update the /etc/hosts
printf "\n Update the server details in /etc/hosts \n"
hostnameLine="${1}"
printf "\n Hostname Line : $hostnameLine\n"
echo $hostnameLine >> /etc/hosts

# Hostname
server=$(echo $hostnameLine | cut -d' ' -f2)


# SSH Setup
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

# Downloading the RPM from Ambari Server node
printf "\n Downloading the RPM from Ambari Server node \n"
command="sshpass -p 'passw0rd' scp -o StrictHostKeyChecking=no -r root@${server}:/opt/SupportAssistant/rpm/*.* /opt/SupportAssistant/rpm/"
eval $command


printf "\n Installing RPMs \n"
cd /opt/SupportAssistant/rpm ; yum -y install ambari-agent-*.rpm \
                    ambari-infra-solr-client-*.rpm \
                    ambari-logsearch-logfeeder-*.rpm

# Update the server hostname in /etc/ambari-agent/conf/ambari-agent.ini
printf "\n Updating the server details in /etc/ambari-agent/conf/ambari-agent.ini \n"
command="sed -i 's/hostname=localhost/hostname=${server}/g' /etc/ambari-agent/conf/ambari-agent.ini"
eval $command

# Update the TLS
printf "\n Updating the TLS property in /etc/ambari-agent/conf/ambari-agent.ini \n"
command="echo $'\n\n[security]\nforce_https_protocol=PROTOCOL_TLSv1_2\n' >> /etc/ambari-agent/conf/ambari-agent.ini"
eval $command


# Start the Agent
printf "\n Starting the Ambari Agent \n"
export buildNumber=2.6.1.0.0
ambari-agent start
sleep 5s



