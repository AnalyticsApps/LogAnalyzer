#!/bin/bash

# Set the buildnumner
export buildNumber=2.6.1.0.0

ambari-agent stop
ambari-server stop

sleep 5s

printf "\n Server stopped \n"
