#!/bin/sh

packArtifacts(){

    ##################################################
    ##### Package the collected logs
    ##################################################

    currentNode=`hostname -f`

    for node in $nodes
        do
                if (ssh $node "test -d $pmrDIR/*/"); then
            ssh $node "cd $pmrDIR/*/;tar czf $pmrDIR/$node.tar.gz * ;"
            scp $node:$pmrDIR/$node.tar.gz $pmrDIR
            if [ "$node" != "$currentNode" ]; then
                ssh $node "rm -rf  $pmrDIR"
            fi
        else
            if [ "$node" != "$currentNode" ]; then
                ssh $node "rm -rf  $pmrDIR"
            fi
        fi

    done 

    rm -rf $pmrDIR/*/
    cd $pmrDIR

    count=`ls -1 $pmrDIR/*.tar.gz 2>/dev/null | wc -l`

    if [ $count != 0 ]; then
        echo " "
        echo "Packaging PMRStamping data..."
        echo " "

        tar czf "$pmrDIR".tar.gz *
        rm -rf $pmrDIR
        echo " "
        echo "!!!!!!!!!!!!! Execution completed.!!!!!!!!!!!!"
        echo "!!!!!!!!!!!!! Please check in $pmrDIR.tar.gz !!!!!!!!!!!!"
        echo " "


    else
        echo " "
        rm -rf $pmrDIR
        echo "!!!!!!!!!!!!! No Logs are modified after $previousDate from nodes: $inputNodes for the selected Service. !!!!!!!!!!!!"
        echo "!!!!!!!!!!!!! Execution completed. No Logs collected. !!!!!!!!!!!!"
        echo " "


    fi



}

writeLogs(){
    node=$1
    srcLogPath=$2
    targetLogPath=$3
    commandSEDArg="s|$srcLogPath||"
    if (ssh $node "test -d $srcLogPath"); then

    echo " "
    command=`ssh $node find $srcLogPath -type d | sed $commandSEDArg`
    directories=$(echo $command | tr " " "\n")
    command=`ssh $node find $srcLogPath -type f -newermt $previousDate`
    files=$(echo $command | tr " " "\n")
    for srcfile in ${files[@]}
    do
        targetfile=$targetLogPath`echo $srcfile | sed $commandSEDArg`
        ssh $node mkdir -p "$targetLogPath"
        ssh $node cp $srcfile $targetLogPath
    done
    else
        echo " "
    
    fi

}

collectLogs(){

    for node in $nodes
    do
        for lPath in $logPath
        do
            echo ""
            echo "Collecting Logs from path : $lPath from Node: $node and path $pmrDIR/$node$lPath"
            writeLogs $node $lPath $pmrDIR/$node$lPath
        done
    
    done 
}

echo " "
echo " "
read -p " Case No# : " pmrNo
if [ "$pmrNo" == "" ]; then
    printf "\n  Enter a valid PMR NO#. \n"
    exit 1
fi

echo " "
echo " "
read -p  " Date (yyyy-mm-dd) issue happened : " issueDate
issueDate=$(date -d "$issueDate" +%F)
previousDate=$(date -d "$issueDate -1 days" +%F)

echo " "
echo " "
read -p  " Component : " component


echo " "
echo " "
echo " Description of the issue (\"ctrl+d\" when done) : " 
issueDesc=$(cat)


echo " "
echo " "
read -p "Location where the logs need to be collected (Default Path - \tmp) : " loc
if [ "$loc" == "" ]; then
    loc="/tmp"
fi

echo " "
echo " "
echo "Services running in your Cluster       "
echo " "
echo " "
echo "1)  Ambari Server & Agents"
echo "2)  Ambari Metrics"
echo "3)  Ambari Infra"
echo "4)  HDFS"
echo "5)  Yarn"
echo "6)  MapReduce2"
echo "7)  Zookeeper"
echo "8)  Hive"
echo "9)  Hbase"
echo "10) Ranger"
echo "11) Knox"
echo "12) Flume"
echo "13) Kafka"
echo "14) Oozie"
echo "15) Spark"
echo "16) Spark2"
echo "17) Zeppelin"


echo " "
echo " "
read -p  "Enter the service no# for collecting the logs. If you have multiple service logs to be collected, provide the service no# delimited by comma : " serviceNos



services=$(echo $serviceNos | tr "," "\n")

logPath=";"
addedMapReduceLog="false"
for service in $services
do
    service="${service#"${service%%[![:space:]]*}"}"
    service="${service%"${service##*[![:space:]]}"}"
    if [ "$service" = "1" ]; then
        logPath="${logPath}/var/log/ambari-agent;/var/log/ambari-server;"
    elif [ "$service" = "2" ]; then
        logPath="${logPath}/var/log/ambari-metrics-collector;/var/log/ambari-metrics-monitor;/var/log/ambari-metrics-grafana;"
    elif [ "$service" = "3" ]; then
        logPath="${logPath}/var/log/ambari-infra-solr;"
    elif [ "$service" = "4" ]; then
        logPath="${logPath}/var/log/hadoop/hdfs;"
    elif [ "$service" = "5" ]; then
        logPath="${logPath}/var/log/hadoop-yarn/yarn;"
        if [ "$addedMapReduceLog" == "false" ]; then
            logPath="${logPath}/var/log/hadoop-mapreduce;"
            addedMapReduceLog="true"
        fi

    elif [ "$service" = "6" ]; then
        if [ "$addedMapReduceLog" == "false" ]; then
            logPath="${logPath}/var/log/hadoop-mapreduce;"
            addedMapReduceLog="true"
        fi
    elif [ "$service" = "7" ]; then
        logPath="${logPath}/var/log/zookeeper;"
    elif [ "$service" = "8" ]; then
        logPath="${logPath}/var/log/hive;/var/log/webhcat;"
    elif [ "$service" = "9" ]; then
        logPath="${logPath}/var/log/hbase;"
    elif [ "$service" = "10" ]; then
        logPath="${logPath}/var/log/ranger;"
    elif [ "$service" = "11" ]; then
        logPath="${logPath}/var/log/knox;"
    elif [ "$service" = "12" ]; then
        logPath="${logPath}/var/log/flume;"
    elif [ "$service" = "13" ]; then
        logPath="${logPath}/var/log/kafka;"
    elif [ "$service" = "14" ]; then
        logPath="${logPath}/var/log/oozie;"
    elif [ "$service" = "15" ]; then
        logPath="${logPath}/var/log/spark;/var/log/livy;"
    elif [ "$service" = "16" ]; then
        logPath="${logPath}/var/log/spark2;"
    elif [ "$service" = "17" ]; then
        logPath="${logPath}/var/log/zeppelin;"
    else
    echo ""
    fi

done

echo " "
echo " "
read -p  "Enter the full host names of the nodes. If you need to collect the logs from multiple nodes, provide the hostname delimited by comma : " inputNodes
logPath=${logPath:1}
#logPath=${logPath::-1}
pmrDIR=$loc/$pmrNo


nodes=$(echo $inputNodes | tr "," "\n")
logPath=$(echo $logPath | tr ";" "\n")


for node in $nodes
    do
        ssh $node rm -rf $pmrDIR
        ssh $node mkdir -p $pmrDIR

    done 

pmrfile=$pmrDIR/pmrstamp.info
touch $pmrfile
echo "Time and date of this collection: `date`" >> $pmrfile
echo "PMR No#   : $pmrNo" >> $pmrfile
echo "Location  : $loc" >> $pmrfile
echo "Log Path  : $logPath" >> $pmrfile


pa=$pmrDIR/problemStatement.info
echo "Case No#   : $pmrNo" >> $pa
echo "Date issue happened   : $issueDate" >> $pa
echo "Component   : $component" >> $pa
echo "Issue Description   : $issueDesc" >> $pa

machineDetails=$pmrDIR/nodes.info
echo "$nodes" >> $machineDetails


collectLogs

packArtifacts
echo -e
