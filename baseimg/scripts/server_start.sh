#!/bin/bash

# Set the build no#
export buildNumber=2.6.1.0.0

ambari-server start
ambari-agent start
sleep 60s

printf "\n Ambari Server and Agent started. \n"


