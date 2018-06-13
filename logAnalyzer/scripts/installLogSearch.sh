#!/bin/sh

function checkLogSearchStarted(){
        while :
        do
                if curl -i -u admin:passw0rd -H 'X-Requested-By:ambari' -X GET http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH 2>&1 | grep "STARTED" > /dev/null  2>&1
                then
                        break
                fi
                printf "\n Sleeping 60s \n"
                sleep 60s
        done
}


cd /opt/SupportAssistant/logAnalyzer/blueprint/

# Register the Blueprint
curl -H 'X-Requested-By:ambari' -X POST -u admin:passw0rd http://localhost:8080/api/v1/blueprints/LogSearchBlueprint -d @Blueprints.json

# Deploy the blueprint
curl -H 'X-Requested-By:ambari' -X POST -u admin:passw0rd http://localhost:8080/api/v1/clusters/LogAnalyzer -d @Hostmapping.json

sleep 120s

checkLogSearchStarted