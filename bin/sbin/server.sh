#!/bin/bash

sdir="`dirname \"$0\"`"

function getServer(){
    cat $sdir/../../conf/server
}

function getOS(){
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        *)          machine="UNKNOWN:${unameOut}"
    esac
    printf ${machine}
}

function buildImage(){
    # Build the docker image
    rm -rf $sdir/../../log/*.*
    printf "\n\n Building the Docker image"
    printf "\n Check the $sdir/../../log/build.log for progress of the build."
    docker kill nodeimg > $sdir/../../log/build.log 2>&1
    docker rm nodeimg >> $sdir/../../log/build.log 2>&1
    local server=$(getServer)

    #docker build --rm --no-cache -t nodeimg $sdir/../../baseimg/ >> $sdir/../../log/build.log 2>&1
    docker build --rm -t nodeimg $sdir/../../baseimg/ >> $sdir/../../log/build.log 2>&1
    printf "\n Building the Docker image completed."
}

function deployImage(){
    # Run the docker image
    printf "\n\n Deploying the docker image"
    printf "\n Check the $sdir/../../log/server_run.log for progress of the execution."
    local server=$(getServer)
    docker run --privileged --name $server -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 8080:8080 -p 21:22 -p 61888:61888 -p 8886:8886 -d -h=$server -e buildNumber='2.6.1.0.0' -it nodeimg > $sdir/../../log/server_run.log 2>&1
    printf "\n Deploying the docker image completed."

}

function configureImage(){

    printf "\n\n"
    read -p  " Provide the URL for ambari.repo file : " repoPath
    printf "\n Ambari Repo URL ->  $repoPath \n" > $sdir/../../log/server_setup.log 2>&1
    command="wget $repoPath -O $sdir/../../conf/ambari.repo"
    eval $command >> $sdir/../../log/server_setup.log 2>&1

    local server=$(getServer)

    printf "\n\n Downloading the RPMs "
    echo "Copying the Ambari Repo " >> $sdir/../../log/server_setup.log
    command="docker cp $sdir/../../conf/ambari.repo $server:/etc/yum.repos.d"
    eval $command >> $sdir/../../log/server_setup.log 2>&1

    echo "Running Yum Clean all " >> $sdir/../../log/server_setup.log
    command="docker exec $server bash -c 'yum clean all'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1

    echo "Downloading RPM from repo " >> $sdir/../../log/server_setup.log
    command="docker exec $server bash -c 'yum install --downloadonly --downloaddir=/opt/SupportAssistant/rpm/ ambari-server ambari-agent ambari-infra-solr-client ambari-infra-solr ambari-logsearch-logfeeder ambari-logsearch-portal'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1


    # Configure the Ambari Server
    printf "\n\n Configure the Ambari Server "
    printf "\n Check the $sdir/../../log/server_setup.log for progress of configuring the Ambari."
    local server=$(getServer)
    docker exec $server bash -c '/opt/SupportAssistant/bin/server_setup.sh' > $sdir/../../log/server_setup.log 2>&1
    
    echo "Setting the buildNumber " >> $sdir/../../log/server_setup.log
    command="docker exec $server bash -c 'echo \"export buildNumber=2.6.1.0.0\" >> ~/.bashrc'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1
    
    echo "Removing the setup folder " >> $sdir/../../log/server_setup.log
    command="docker exec $server bash -c 'rm -rf /opt/SupportAssistant/bin/server_setup.sh /opt/SupportAssistant/bin/agent_setup.sh /opt/SupportAssistant/bin/agent_start.sh /opt/SupportAssistant/bin/agent_stop.sh /opt/SupportAssistant/logsearchConfig'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1

    echo "Setting up the SSH " >> $sdir/../../log/server_setup.log
    command="docker exec $server bash -c 'sshpass -p "passw0rd" ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@${server}'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1

    sleep 10s
    command="docker exec $server bash -c 'ambari-agent restart'"
    eval $command >> $sdir/../../log/server_setup.log 2>&1
    sleep 60s


    printf "\n Configure the Ambari Server completed."

}

function displayServerConnectionDetails(){
    printf "\n\n\n ********************************************************"
    printf "\n\n To login to Ambari UI -> localhost:8080"
    printf "\n Credentials for Ambari UI -> admin/passw0rd"
    printf "\n To login to LogSearch UI -> localhost:61888"
    printf "\n Credentials for LogSearch UI -> admin/passw0rd"
    printf "\n\n To Login to Ambari Server Linux terminal -> ssh -p 21 root@localhost"
    printf "\n Password for root user -> passw0rd"
    printf "\n\n ********************************************************\n"

}

function start() {
    rm -rf $sdir/../../log/server_start.log
    printf "\n\n Starting the Server \n"
    printf " Check the $sdir/../../log/server_start.log for progress \n"
    local server=$(getServer)
    docker start $server > $sdir/../../log/server_start.log 2>&1
    printf " Starting the service \n"
    docker exec $server bash -c '/opt/SupportAssistant/bin/server_start.sh' >> $sdir/../../log/server_start.log 2>&1
    printf "\n\n Server started successfuly. \n"
}

function stop() {           
    rm -rf $sdir/../../log/server_stop.log
    printf "\n\n Stopping the Server \n"
    printf " Check the $sdir/../../log/server_stop.log for progress"
    local server=$(getServer)
    printf "\n Stoping the service "
    docker exec $server bash -c '/opt/SupportAssistant/bin/server_stop.sh' > $sdir/../../log/server_stop.log 2>&1
    docker stop $server >> $sdir/../../log/server_stop.log 2>&1
    printf "\n Server Stopped successfuly. \n\n"
}

function help() {

    printf "\n\n\n # Usage : \"./server.sh <command>\""
    printf "\n #"
    printf "\n #"
    printf "\n #\n #  \"./server.sh help\"       # Help for running commands"
    printf "\n #\n #  \"./server.sh create\"     # Create the Docker images and configure the Ambari Log Search."
    printf "\n #                           # The Docker images for Ambari Server is created based on the name mentioned in property file conf/server"
    printf "\n #                           # The Docker images for Ambari Agents are created based on the names mentioned in property file conf/agents"
    printf "\n #                           # The image name and hostname will be same as the names mentioned in conf/server & conf/agents"
    printf "\n #                           # The connection details to connect to Linux terminal for all created images and UI login details are stored in "
    printf "\n #                           # conf/serverConnectionDetails"
    printf "\n #\n #  \"./server.sh start\"      # Start the Docker images and start the Ambari Log Search."
    printf "\n #\n #  \"./server.sh stop\"       # Stop the Docker images and stop the Ambari Log Search."
    printf "\n #\n #\n"
}
function process() {
    command="$1"
    shift
    case $command in
        "create")
                
            buildImage
            deployImage
            configureImage
            #displayServerConnectionDetails
            displayServerConnectionDetails > $sdir/../../conf/serverConnectionDetails
            printf "\n\n\n Setting up and configuring the Ambari Server is completed.\n\n"
            ;;
        "start")
            start
            #displayServerConnectionDetails
            ;;
        "stop")
            stop
            ;;
        "help")
                help
            ;;
        *)
            echo "Available commands: (create|start|stop|help). Run \"./server.sh help\" for argument details. "
        ;;
    esac
}

: ${1:?" Argument is missing. Run \"./server.sh help\" for argument details. "}
process "$@"
