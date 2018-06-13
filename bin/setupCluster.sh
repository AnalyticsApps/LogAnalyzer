#!/bin/sh

sdir="`dirname \"$0\"`"

function setupCluster(){

        printf "\n\n\n ****************************************************************************************************************"
        printf "\n Setting up the Server \n"
        printf " ****************************************************************************************************************"
        $sdir/sbin/server.sh create
        sleep 5s
        printf "\n ****************************************************************************************************************"
        printf "\n Setting up the Agents \n"
        printf " ****************************************************************************************************************"
        $sdir/sbin/agent.sh create
        printf "\n\n\n Setting up and configuring the Agents completed.\n\n"

        command="$1"
        if [ "$command" == "createLogAnalyzer" ]; then
            $sdir/sbin/setupLogAnalyzer.sh
        fi


        printf "\n\n\n ****************************************************************************************************************"
        printf "\n                     Cluster Setup completed !!!!!!!!!!! \n"
        printf " ****************************************************************************************************************\n\n"

}

function help() {

    printf "\n\n\n # Usage : \"./setupCluster.sh <command>\""
    printf "\n #"
    printf "\n #"
    printf "\n #\n #     \"./setupCluster.sh help\"                    # Help for running commands"
    printf "\n #\n #     \"./setupCluster.sh createLogAnalyzer\"       # Create the Docker images and configure the Ambari Log Search."
    printf "\n #                                                 # The Docker images for Ambari Server is created based on the name mentioned in property file conf/server"
    printf "\n #                                                 # The Docker images for Ambari Agents are created based on the names mentioned in property file conf/agents"
    printf "\n #                                                 # The image name and hostname will be same as the names mentioned in conf/server & conf/agents"
    printf "\n #                                                 # The connection details to connect to Linux terminal for all created images and UI login details are stored "
    printf "\n #                                                 # in conf/serverConnectionDetails"
    printf "\n #\n #     \"./setupCluster.sh start\"                   # Start the Docker images and start the Ambari Services."
    printf "\n #\n #     \"./setupCluster.sh stop\"                    # Stop the Docker images and stop the Services."
    printf "\n #\n #\n"
}

function process() {
    command="$1"
    shift
    case $command in
        "createLogAnalyzer")
            setupCluster createLogAnalyzer
            ;;
        "start")
            $sdir/sbin/agent.sh start
            $sdir/sbin/server.sh start
            cat $sdir/../conf/serverConnectionDetails
            cat $sdir/../conf/agentConnectionDetails
            ;;
        "stop")
            $sdir/sbin/agent.sh stop
            $sdir/sbin/server.sh stop
            ;;
        "help")
                help
            ;;
        *)
            echo "Available commands: (createLogAnalyzer|start|stop|help). Run \"./setupCluster.sh help\" for argument details. "
        ;;
    esac
}

: ${1:?" Argument is missing. Run \"./setupCluster.sh help\" for argument details. "}
process "$@"
