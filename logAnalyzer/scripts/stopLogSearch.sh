#!/bin/sh

function checkLogSearchStopped(){
        while :
        do
                if curl -i -u admin:passw0rd -H 'X-Requested-By:ambari' -X GET http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH 2>&1 | grep "INSTALLED" > /dev/null  2>&1
                then
                        break
                fi
                printf "\n Sleeping 60s \n"
                sleep 60s
        done
}

printf "\n Stopping Log Search \n"

#stop service
printf "\n Stopping AMBARI_INFRA \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop AMBARI_INFRA via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/AMBARI_INFRA
sleep 10

printf "\n Stopping ZOOKEEPER \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop ZOOKEEPER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/ZOOKEEPER
sleep 10s

printf "\n Stopping LOGSEARCH \n"
curl -u admin:passw0rd -i -H 'X-Requested-By:ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop LOGSEARCH via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH

checkLogSearchStopped

printf "\n Log Search Stopped \n"
