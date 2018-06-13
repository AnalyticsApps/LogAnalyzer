#!/bin/bash

# update the /etc/hosts
printf "\n Update the server details in /etc/hosts \n"
hostnameLine="${1}"
printf "\n Hostname Line : $hostnameLine \n"
echo $hostnameLine >> /etc/hosts

# Start the Ambari Agent
export buildNumber=2.6.1.0.0
ambari-agent start
sleep 5s
printf "\n Ambari Agent started. \n"
