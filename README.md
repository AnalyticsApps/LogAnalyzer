# LogAnalyzer
Log Analyzer for analysing the customer logs for bigdata components like HDFS, Hive, HBase, Yarn, MapReduce, Storm, Spark, Spark 2, Knox, Ambari Metrics, Nifi, Accumulo, Kafka, Flume, Oozie, Falcon, Atlas & Zookeeper.

## Internal Architecture

Analysing the Customer logs for understanding the issue is a time consuming process. For a BigData issue, the Support Engineer need to slice and dice the logs from various components across different nodes to understand the issue. There are many paid products available that helps in analysing these logs. Here we use the the Ambari Log Search Feature to analyse the logs. The Amabri Log Search is used to analyse the logs in that cluster and it expects all the components to be installed so that it will check the issues of the installed components in that cluster. This project creates the docker containers based on the nodes provided by Customer and setup the Amabri Log Search in it and Ambari Log Search will be using the customer logs.

Consider a customer has a 20 node Hadoop Cluster and having issues with namenode(node1.test.com) and 2 datanode (node12.test.com, node15.test.com). The Support Engineer has to share the Log Collector Script (bin/logCollector.sh) to Customer. Customer run the script that will collect the logs from 3 nodes (node1.test.com, node12.test.com, node15.test.com). The customer shares the zipped artifact to support engineer. 

The Support Engineer run the bin/setup.sh and share the path for the collected artifact. This script will create 3 docker containers for each node (node1.test.com, node12.test.com, node15.test.com). The container name will be same as host name. Here the script take the first container (node1.test.com) and setup the ambari server. Ambari agents will be installed in rest all the container. Then the script creates the Ambari Blueprints and install the Log Search. Only dependent components for Log Search will be installed in the cluster. After the installation, the script will update the Log Search to point to customer logs. This script takes 10-15 mins to setup the Log Analyzer. 

The Support Engineer uses he URL http://<HostIP>:61888/login.html to analyze the logs. The credentials are admin/passw0rd
The Support Engineer can login to Amabri Server (http://<HostIP>:8080/) using credentials admin/passw0rd
The Support Engineer can login to these containers or Ambari nodes from linux terminal using ssh -p <assignedPort> root@localhost
The <assignedPort> and login details for each containers are updated in conf/serverConnectionDetails & conf/agentConnectionDetails


After analysing the logs, Support Engineer will run bin/kill_all.sh that will kill/remove these containers.


logCollector.sh - Used by Customer to collect the logs. Customer need to provide the Case details, issue details, date when the issue occurred, components for which logs to be collected, nodes for which logs to be collected and path where the final artifact to be generated. Based on the customer input the script will collect the logs.
 
![](img/logCollector_1.png)
![](img/logCollector_2.png)

setupDocker.sh  - Used to setup the Docker in a Linux Machine

setup.sh - Used to setup the Cluster based on Customer hostname and distribute the customer logs for analysis.

setupCluster.sh - Used for setup the cluster based on the nodes mentioned in configuration files

logDistribute.sh - Used for distributing the customer logs to existing cluster

kill_all.sh - Used to kill the containers running.







