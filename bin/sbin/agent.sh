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


function deployImage(){
    # Run the docker image
    printf "\n\n Deploying the docker images"
    port=23
    for i in `cat $sdir/../../conf/agents`
    do
            agent=${i}
            printf "\n\n\n Running the docker image for $agent "
            printf "\n Check the $sdir/../../log/agent_run_$agent.log for progress of the execution."
            docker run --privileged --name $agent -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p $port:22 -d -h=$agent -e buildNumber='2.6.1.0.0' -it nodeimg > $sdir/../../log/agent_run_$agent.log 2>&1
            printf "\n Running the docker image for $agent completed."

            # Configure the Ambari Agent
            printf "\n Configure the Ambari Agent - $agent"
            printf "\n Check the $sdir/../../log/agent_setup_$agent.log for progress of configuring the Ambari Agent."

            server=`head -n 1 $sdir/../../conf/server`
            server_host_short_name=$(echo $server | cut -d'.' -f1)
            agent_host_short_name=$(echo $agent | cut -d'.' -f1)
            agent_host_name="$agent $agent_host_short_name"
            ip_address_server=$( docker inspect --format '{{ .NetworkSettings.IPAddress }}' $server > /dev/null 2>&1 )
            if [ $? -eq 0 ]
            then
                    ip_address_agent=$( docker inspect --format '{{ .NetworkSettings.IPAddress }}' $agent)
                    server_command="docker exec $server bash -c 'echo $ip_address_agent $agent_host_name >> /etc/hosts'"
                    eval $server_command > $sdir/../../log/agent_setup_$agent.log 2>&1
                    ip_address_server=$( docker inspect --format '{{ .NetworkSettings.IPAddress }}' $server)
                    command="docker exec $agent bash -c '/opt/SupportAssistant/bin/agent_setup.sh \"$ip_address_server $server $server_host_short_name\"'"
                    eval $command >> $sdir/../../log/agent_setup_$agent.log 2>&1
            
                    echo "Setting the buildNumber " >> $sdir/../../log/agent_setup_$agent.log                
                    command="docker exec $agent bash -c 'echo \"export buildNumber=2.6.1.0.0\" >> ~/.bashrc'"
                    eval $command >> $sdir/../../log/agent_setup_$agent.log 2>&1

                    echo "Removing the RPM " >> $sdir/../../log/agent_setup_$agent.log
                    command="docker exec $agent bash -c 'rm -rf /opt/SupportAssistant/bin/agent_setup.sh /opt/SupportAssistant/bin/server_setup.sh /opt/SupportAssistant/bin/server_start.sh /opt/SupportAssistant/bin/server_stop.sh /opt/SupportAssistant/rpm /opt/SupportAssistant/logsearchConfig '"
                    eval $command >> $sdir/../../log/agent_setup_$agent.log 2>&1

                    echo "Setting up the SSH with server" >> $sdir/../../log/agent_setup_$agent.log
                    command="docker exec $server bash -c 'sshpass -p "passw0rd" ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@${agent}'"
                    eval $command >> $sdir/../../log/agent_setup_$agent.log 2>&1

                    sleep 5s
                    command="docker exec $server bash -c 'ambari-agent restart'"
                    eval $command >> $sdir/../../log/agent_setup_$agent.log 2>&1
                    sleep 5s



                    echo $ip_address_agent $agent_host_name >> $sdir/../../tmp/hosts
                    printf "\n Configure the Ambari Agent - $agent completed.\n"
            else
                    printf "\n\n Server is not running."
                    # TODO - If server not running remove the container and conf property and exit
            fi
        
            port=$((port + 1))
    done

    sleep 90s

    local os=$(getOS)
    for i in `cat $sdir/../../conf/agents`
    do
         agent=${i}
         cp $sdir/../../tmp/hosts $sdir/../../tmp/hosts_$agent
         if [ "$os" = "Mac" ]
         then
              command="sed -i '' '/$agent/d' $sdir/../../tmp/hosts_$agent"
         else
              command="sed -i '/$agent/d' $sdir/../../tmp/hosts_$agent"
         fi
         eval $command > $sdir/../../log/agent_setup.log 2>&1
                
         echo "Updating the host names in /etc/hosts" >> $sdir/../../log/agent_setup.log 2>&1
         command="docker cp $sdir/../../tmp/hosts_$agent $agent:/opt/SupportAssistant/tmp"
         eval $command >> $sdir/../../log/agent_setup.log 2>&1
         command="docker exec $agent bash -c 'cat /opt/SupportAssistant/tmp/hosts_$agent >> /etc/hosts'"
         eval $command >> $sdir/../../log/agent_setup.log 2>&1

     done
     rm -rf $sdir/../../tmp/*

}


function displayAgentConnectionDetails {
    printf "\n\n\n ********************************************************"
    printf "\n                    AGENT LOGIN DETAILS                  "
    printf "\n ********************************************************"
    port=23
    for i in `cat $sdir/../../conf/agents`
    do
        agent=${i}
        printf "\n\n To Login to Agent ( $agent ) terminal -> ssh -p $port root@localhost"
        printf "\n Password for root user -> passw0rd"
        port=$((port + 1))
    done
    printf "\n\n ********************************************************\n\n"

}


function start() {
    rm -rf $sdir/../../log/agent_start.log
    printf "\n\n Starting the Agents \n"
    printf " Check the $sdir/../../log/agent_start.log for progress \n"
    server=`head -n 1 $sdir/../../conf/server`
    ip_address_server=$( docker inspect --format '{{ .NetworkSettings.IPAddress }}' $server)
    server_host_short_name=$(echo $server | cut -d'.' -f1)
    for i in `cat $sdir/../../conf/agents`
        do
            agent=${i}
            printf "\n Starting the docker image for $agent" >> $sdir/../../log/agent_start.log
            docker start $agent >> $sdir/../../log/agent_start.log 2>&1
            sleep 20s
            command="docker exec $agent bash -c '/opt/SupportAssistant/bin/agent_start.sh \"$ip_address_server $server $server_host_short_name\"'"
            eval $command >> $sdir/../../log/agent_start.log 2>&1

            command="docker exec $agent bash -c 'cat /opt/SupportAssistant/tmp/hosts_$agent >> /etc/hosts'"
            eval $command >> $sdir/../../log/agent_setup.log 2>&1

            printf " Started the Ambari Agent \n"
    done

    printf "\n\n Agent Started successfuly. \n\n"
}

function stop() {

        rm -rf $sdir/../../log/agent_stop.log
        printf "\n\n Stopping the Agents \n"
        printf " Check the $sdir/../../log/agent_stop.log for progress \n"
        for i in `cat $sdir/../../conf/agents`
        do
                agent=${i}
                printf "\n Stopping the docker image for $agent" >> $sdir/../../log/agent_stop.log
                docker exec $agent bash -c '/opt/SupportAssistant/bin/agent_stop.sh' >> $sdir/../../log/agent_stop.log 2>&1
                printf " Stopped the Ambari Agent - $agent \n"
                docker stop $agent >> $sdir/../../log/agent_stop.log 2>&1
                printf " Image stopped - $agent \n"
                sleep 5s
        done
        printf "\n Agents Stopped successfuly. \n\n"
}



function help() {

        printf "\n\n\n # Usage : \"./agent.sh <command>\""
        printf "\n #"
        printf "\n #"
        printf "\n #\n #  \"./agent.sh help\"       # Help for running commands"
        printf "\n #\n #  \"./agent.sh create\"     # Create the Docker images and configure the Ambari Agents."
        printf "\n #                          # The Docker images for Ambari Server is created based on the name mentioned in property file conf/server"
        printf "\n #                          # The Docker images for Ambari Agents are created based on the names mentioned in property file conf/agents"
        printf "\n #                          # The image name and hostname will be same as the names mentioned in conf/server & conf/agents"
        printf "\n #                          # The connection details to connect to Linux terminal for all created images and UI login details are stored in "
        printf "\n #                          # conf/serverConnectionDetails & conf/agentConnectionDetails"
        printf "\n #\n #  \"./agent.sh start\"      # Start the Docker images and start all the Ambari Agents."
        printf "\n #\n #  \"./agent.sh stop\"       # Stop the Docker images and stop all the Ambari Agents."
        printf "\n #\n #\n"
}


function process() {
        command="$1"
        shift
        case $command in
                "create")

                        
                        deployImage
                        #displayAgentConnectionDetails
                        displayAgentConnectionDetails > $sdir/../../conf/agentConnectionDetails
                                        ;;
                "start")
                        start
                        #displayAgentConnectionDetails
                ;;
                "stop")
                        stop
                ;;
                "help")
                        help
                ;;
                *)
                        echo "Available commands: (create|start|stop|help). Run \"./agent.sh help\" for argument details. "
                ;;
        esac
}

: ${1:?" Argument is missing. Run \"./agent.sh help\" for argument details. "}
process "$@"
