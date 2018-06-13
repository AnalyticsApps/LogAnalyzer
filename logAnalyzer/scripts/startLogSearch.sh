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

printf "\n Starting Log Search \n"

# start service
printf "\n Starting Ambari Infra \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Start ZOOKEEPER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/ZOOKEEPER
sleep 10s

printf "\n Starting Zookeeper \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Start AMBARI_INFRA via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/AMBARI_INFRA
sleep 10s

printf "\n Starting Log Search \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Sart LOGSEARCH via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH
sleep 10s

checkLogSearchStarted

printf "\n Log Search Started \n"