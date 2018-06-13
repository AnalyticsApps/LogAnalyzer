#!/bin/bash

# Setting the Environment 
printf "\n Preparing the Environment \n"
systemctl enable ntpd.service && systemctl start ntpd.service
timedatectl set-timezone America/New_York
echo never > /sys/kernel/mm/transparent_hugepage/enabled && echo -e "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then \n    echo never > /sys/kernel/mm/transparent_hugepage/enabled\nfi" >> /etc/rc.local

# SSH Setup
ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

printf "\n Installing RPMs \n"
cd /opt/SupportAssistant/rpm ; yum -y install ambari-server-*.rpm ambari-agent-*.rpm \
             ambari-infra-solr-*.rpm ambari-infra-solr-client-*.rpm \
             ambari-logsearch-logfeeder-*.rpm ambari-logsearch-portal-*.rpm

# Hack - When we install Logsearch, the log search looks for installed services and creates the configuration file.
#        Here for log analysis, we are not installing services but logsearch assumes that all the services are installed.

rm -rf /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/templates/HadoopServiceConfig.json.j2
cp /opt/SupportAssistant/logsearchConfig/*.json.j2 /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/templates/
rm -rf /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/properties/logfeeder-default_grok_patterns.j2
cp /opt/SupportAssistant/logsearchConfig/logfeeder-default_grok_patterns.j2 /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/properties/


delLine=$(grep -n "logfeeder_default_services = \['logsearch'\]" /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/scripts/params.py  | cut -d : -f 1)
delCommand="sed -i '${delLine}d' /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/scripts/params.py"
eval $delCommand

service="'logsearch','ambari','infra','zookeeper', 'atlas','hbase','kafka','oozie','yarn','accumulo','hdfs','knox','spark','falcon','hive','spark2','ams','flume','mapred','storm'"
addCommand="sed -i \"${delLine}i\logfeeder_default_services = \[ $service \]\" /var/lib/ambari-server/resources/common-services/LOGSEARCH/*/package/scripts/params.py"
eval $addCommand

printf "\n Setting up the Ambari \n"
export buildNumber=2.6.1.0.0
ambari-server setup -s --java-home=/usr/lib/jvm/java-1.8.0-openjdk


printf "\n Starting the Ambari Server \n"
ambari-server start


printf "\n Install mysql-connector-java for Hive\n"
yum -y install mysql-connector-java
ambari-server setup --jdbc-db=mysql --jdbc-driver=/usr/share/java/mysql-connector-java.jar

command="curl -i -u admin:admin -H \"X-Requested-By: ambari\" -X PUT -d '{\"Users\": { \"user_name\": \"admin\", \"password\": \"passw0rd\", \"old_password\": \"admin\"}}' http://localhost:8080/api/v1/users/admin"
eval $command

# Update the server hostname in /etc/ambari-agent/conf/ambari-agent.ini
server=`hostname -f`
printf "\n Updating the server details in /etc/ambari-agent/conf/ambari-agent.ini \n"
command="sed -i 's/hostname=localhost/hostname=${server}/g' /etc/ambari-agent/conf/ambari-agent.ini"
eval $command


# Update the TLS
printf "\n Updating the TLS property in /etc/ambari-agent/conf/ambari-agent.ini \n"
command="echo $'\n\n[security]\nforce_https_protocol=PROTOCOL_TLSv1_2\n' >> /etc/ambari-agent/conf/ambari-agent.ini"
eval $command


printf "\n Starting the Ambari Agent \n"
ambari-agent start


sleep 5s
printf "\n Ambari installation sucessfull \n"

