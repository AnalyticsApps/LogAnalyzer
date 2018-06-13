#!/bin/sh

sdir="`dirname \"$0\"`"

function createHostMapping(){

    cp -f $sdir/../../logAnalyzer/blueprint/Hostmapping.json $sdir/../../tmp

    serverDetails="\t{\n\t\t\"name\" : \"host_server\",\n\t\t\"hosts\" : [\n\t\t\t{\n\t\t\t\t\"fqdn\" : \"$server\"\n\t\t\t}\n\t\t]\n\t}\n"
    comm="sed -i 's/ADD_SERVER/$serverDetails/g'  $sdir/../../tmp/Hostmapping.json"
    eval $comm

    if [[ $(wc -l < $sdir/../../conf/agents) -eq 0 ]]; then
          comm="sed -i 's/ADD_AGENTS/ /g'  $sdir/../../tmp/Hostmapping.json"
          eval $comm
    else
  
          agentDetailsHead="\t,{\n\t\t\"name\" : \"host_agents\",\n\t\t\"hosts\" : [\n\t\t\t"

          agentDetails=""
          declare -i start=1
   
          for i in `cat $sdir/../../conf/agents`
          do
              agent=${i}

              if (( $start == 1 )) ; then
                    agentDetails="$agentDetails{\n\t\t\t\t\"fqdn\" : \"$agent\"\n\t\t\t}"
              else
                    agentDetails="$agentDetails\n\t\t\t,{\n\t\t\t\t\"fqdn\" : \"$agent\"\n\t\t\t}"
 
              fi
              start+=1
              
          done

          agentDetailsFooter="\n\t\t]\n\t}\n"
    
          agentDetails="$agentDetailsHead$agentDetails$agentDetailsFooter"

         comm="sed -i 's/ADD_AGENTS/$agentDetails/g'  $sdir/../../tmp/Hostmapping.json"
         eval $comm

    fi

}

function displayLogSearchDetails(){
    printf "\n\n\n ********************************************************"
    printf "\n To login to LogSearch UI -> localhost:61888"
    printf "\n Credentials for LogSearch UI -> admin/passw0rd"
    printf "\n\n ********************************************************\n"

}


function installLogAnalyzer(){

    server=`head -n 1 $sdir/../../conf/server`


    command="docker cp $sdir/../../logAnalyzer $server:/opt/SupportAssistant"
    eval $command >> $sdir/../../log/logAnalyzer_setup.log 2>&1

    command="docker exec $server bash  -c 'chmod -R 777 /opt/SupportAssistant'"
    eval $command >> $sdir/../../log/logAnalyzer_setup.log 2>&1

    createHostMapping

    command="docker cp $sdir/../../tmp/Hostmapping.json $server:/opt/SupportAssistant/logAnalyzer/blueprint/Hostmapping.json"
    eval $command >> $sdir/../../log/logAnalyzer_setup.log 2>&1

    command="docker exec $server bash  -c '/opt/SupportAssistant/logAnalyzer/scripts/installLogSearch.sh'"
    eval $command >> $sdir/../../log/logAnalyzer_setup.log 2>&1



    printf "\n\n logAnalyzer install Completed \n\n"
}

installLogAnalyzer
displayLogSearchDetails

