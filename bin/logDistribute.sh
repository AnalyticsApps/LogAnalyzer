#!/bin/sh

sdir="`dirname \"$0\"`"

LogSearchExt_Temp="$sdir/../tmp"
server=`head -n 1 $sdir/../conf/server`

function checkServiceStatus(){
        service="$1"
        status="$2"
        printf "\n Checking the Service - service for status - $status \n"  >> $sdir/../log/logDistribute.log 2>&1
        while :
        do
                if curl -i -u admin:passw0rd -H 'X-Requested-By:ambari' -X GET http://localhost:8080/api/v1/clusters/LogAnalyzer/services/$service 2>&1 | grep "$status" > /dev/null  2>&1
                then
                        printf "\n $service is $status\n" >> $sdir/../log/logDistribute.log 2>&1
                        break
                fi
                printf "\n Sleeping 5s \n" >> $sdir/../log/logDistribute.log 2>&1
                sleep 5s
        done
}

setupAgent(){
       agent="${1}"
 
       command="docker exec $agent bash -c 'rm -rf /opt/LogSearchExt/logs && mkdir -p /opt/LogSearchExt/logs && chmod -R 777 /opt/LogSearchExt'"
       eval $command >> $sdir/../log/logsearchExt.log 2>&1

       command="docker exec $agent bash -c 'rm -rf /etc/ambari-logsearch-logfeeder/conf/checkpoints/*.*'"
       eval $command >> $sdir/../log/logsearchExt.log 2>&1

}


distribute() {

        printf "\n\n\n ****************************************************************************************************************"
        printf "\n Distributing the logs \n"
        printf " ****************************************************************************************************************"


        pmrPath="${1}"
        if [ -z "$pmrPath" ]; then
                printf "\n\n"
                read -p  " Provide the log collector (PMR_NO.tar.gz) path : " pmrPath
        fi

        printf "\n PMR File ->  $pmrPath \n" > $sdir/../log/logDistribute.log 2>&1

        rm -rf $LogSearchExt_Temp/*
        tar -C $LogSearchExt_Temp -xvf $pmrPath > $sdir/../log/logDistribute.log 2>&1

        nodes=`cat $sdir/../conf/server $sdir/../conf/agents`

        nodesInLogs=`find $LogSearchExt_Temp/*.tar.gz -maxdepth 0 -type f`
        nodesInLogs=($nodesInLogs)

        # Stop the logsearch
        printf "\n\n Stopping the Logsearch Service \n\n"
        command="curl -u admin:passw0rd -H 'X-Requested-By:ambari' -i -X PUT -d '{\"RequestInfo\": {\"context\" :\"Stop LOGSEARCH\"}, \"Body\": {\"ServiceInfo\": {\"maintenance_state\" : \"OFF\", \"state\": \"INSTALLED\"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH"
        eval $command > $sdir/../log/logDistribute.log 2>&1
        sleep 10s
        checkServiceStatus "LOGSEARCH" "INSTALLED"


       solrURL="http://localhost:8886/solr"
       curl -s $solrURL/hadoop_logs/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8' >> $sdir/../log/logDistribute.log 2>&1
       curl -s $solrURL/hadoop_logs/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8' >> $sdir/../log/logDistribute.log 2>&1
       curl -s $solrURL/audit_logs/update --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8' >> $sdir/../log/logDistribute.log 2>&1
       curl -s $solrURL/audit_logs/update --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8' >> $sdir/../log/logDistribute.log 2>&1

       sleep 10s


       server=`head -n 1 $sdir/../conf/server`
       server_command="docker exec $server bash -c 'ambari-server stop'"
       eval $server_command >> $sdir/../log/logDistribute.log 2>&1

       server_command="docker exec $server bash -c 'ambari-agent stop'"
       eval $server_command >> $sdir/../log/logDistribute.log 2>&1


        for index in `cat $sdir/../conf/agents`
        do
                agent=${index}
                command="docker exec $agent bash -c 'ambari-agent stop'"
                eval $command >> $sdir/../log/logDistribute.log 2>&1

        done

        setupAgent $server
        for i in `cat $sdir/../conf/agents`
        do
                agent=${i}
                setupAgent $agent
        done

        server_command="docker exec $server bash -c 'rm -rf /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/properties/input.config-ambari.json.j2 && cp /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/templates/input.config-ambari.json.j2 /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/properties/'"
        eval $server_command >> $sdir/../log/logsearchExt.log 2>&1


        declare -i index=0
        for node in `cat $sdir/../conf/server $sdir/../conf/agents`
        do
                logFile=${nodesInLogs[index]}
                logFile=${logFile#$LogSearchExt_Temp/}
                
                printf " Distributing the log to node ${node} under the path /opt/LogSearchExt/logs/  \n"
                logDir=${logFile%.tar.gz}
                
                command="docker exec ${node} bash -c 'rm -rf /opt/LogSearchExt/logs/*'"
                eval $command >> $sdir/../log/logDistribute.log 2>&1

                command="docker cp $LogSearchExt_Temp/$logFile ${node}:/opt/LogSearchExt/logs/"
                eval $command >> $sdir/../log/logDistribute.log 2>&1

                command="docker exec ${node} bash -c 'tar -C /opt/LogSearchExt/logs -xvf /opt/LogSearchExt/logs/$logFile && rm -rf /opt/LogSearchExt/logs/$logFile'"
                eval $command >> $sdir/../log/logDistribute.log 2>&1

                command="docker cp $LogSearchExt_Temp/pmrstamp.info ${node}:/opt/LogSearchExt/logs/"
                eval $command >> $sdir/../log/logDistribute.log 2>&1

                index=index+1
        done


       server_command="docker exec $server bash -c 'ambari-server start'"
       eval $server_command >> $sdir/../log/logDistribute.log 2>&1

       server_command="docker exec $server bash -c 'ambari-agent start'"
       eval $server_command >> $sdir/../log/logDistribute.log 2>&1


        for i in `cat $sdir/../conf/agents`
        do
                agent=${i}
                command="docker exec $agent bash -c 'ambari-agent start'"
                eval $command >> $sdir/../log/logDistribute.log 2>&1
        done

        sleep 60s

 
        # Start the logsearch
        printf "\n\n Starting the LOGSEARCH"
        command="curl -u admin:passw0rd -H 'X-Requested-By:ambari' -i -X PUT -d '{\"RequestInfo\": {\"context\" :\"Start LOGSEARCH\"}, \"Body\": {\"ServiceInfo\": {\"maintenance_state\" : \"OFF\", \"state\": \"STARTED\"}}}' http://localhost:8080/api/v1/clusters/LogAnalyzer/services/LOGSEARCH"
        eval $command > $sdir/../log/logDistribute.log 2>&1
        sleep 10s
        checkServiceStatus "LOGSEARCH" "STARTED"
       
        rm -rf $LogSearchExt_Temp/*

        printf "\n\n\n ****************************************************************************************************************"
        printf "\n Distributing of logs completed !! \n"
        printf " ****************************************************************************************************************"

        hostN=`hostname -f`
        
        printf "\n\n\n You can login to Log Search UI - $hostN:61888  for Log Analysis. Credentials for LogSearch UI: admin/passw0rd \n\n"
        

}

distribute "$@"

