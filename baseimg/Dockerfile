FROM centos:7
  
ENV container docker

MAINTAINER SupportAssistant 1.0 <Nisanth Simon>

ARG HOSTNAME=node.sample.com
ARG CREDENTIALS=root:passw0rd
ARG JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

ENV HOSTNAME=$HOSTNAME

# yum update - Upgrade all of your CentOS system software to the latest version with one operation.
# yum clean all - Clean the cache. The package cache is stored in /var/cache/yum
#                 /etc/yum.conf has the yum config details. This property has the cache directory, keepcache, log
RUN yum -y update; yum clean all

RUN yum -y install openssh-server sshpass; yum clean all

# Set the password for root user
RUN echo ${CREDENTIALS} | chpasswd

# initscripts is used to setup service command. Service command is used to start/stop the services, like service MySERVICE start.
# To view, start, stop, restart, enable, or disable system services you will use the systemctl instead of the old service command.
# service was there as part of centos6. In centos7, it is removed.
# in Centos7, we use systemd instead of service command
# initscript - The initscripts package contains system scripts to boot your system, change runlevels, activate and deactivate most network interfaces, and shut the system down cleanly.
RUN yum -y install initscripts;

RUN yum -y install epel-release


RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -df /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;


RUN yum install -y systemd* && yum clean all

RUN yum install -y yum-utils yum-plugin-ovl tar git curl bind-utils unzip wget && yum clean all

RUN systemctl enable sshd

RUN yum install -y ntp

RUN yum -y install java-1.8.0-openjdk && yum -y install java-1.8.0-openjdk-devel
ENV JAVA_HOME=$JAVA_HOME
ENV PATH=$JAVA_HOME/bin:$PATH


RUN mkdir -p /opt/SupportAssistant /opt/SupportAssistant/rpm /opt/SupportAssistant/bin /opt/SupportAssistant/tmp /opt/SupportAssistant/logsearchConfig
WORKDIR /opt/SupportAssistant

COPY logsearchConfig/HadoopServiceConfig.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-hbase.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-kafka.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-oozie.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-yarn.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-accumulo.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-hdfs.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-knox.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-spark.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-falcon.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-hive.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-spark2.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-ams.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-flume.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-mapred.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-storm.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-atlas.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-ambari.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-infra.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-logsearch.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-zookeeper.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/input.config-nifi.json.j2 /opt/SupportAssistant/logsearchConfig/
COPY logsearchConfig/logfeeder-default_grok_patterns.j2 /opt/SupportAssistant/logsearchConfig/


COPY scripts/server_setup.sh /opt/SupportAssistant/bin/
COPY scripts/server_stop.sh /opt/SupportAssistant/bin/
COPY scripts/server_start.sh /opt/SupportAssistant/bin/
COPY scripts/agent_setup.sh /opt/SupportAssistant/bin/
COPY scripts/agent_stop.sh /opt/SupportAssistant/bin/
COPY scripts/agent_start.sh /opt/SupportAssistant/bin/


RUN chmod -R 777 /opt/SupportAssistant/

ENV buildNumber 2.6.1.0.0

VOLUME [ "/sys/fs/cgroup" ]

ENTRYPOINT ["/usr/sbin/init"]

EXPOSE 22
EXPOSE 8080
EXPOSE 61888
EXPOSE 8886

