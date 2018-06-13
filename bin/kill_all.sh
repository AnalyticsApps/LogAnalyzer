#!/bin/sh

sdir="`dirname \"$0\"`"

# Remove the Agents
for index in `cat $sdir/../conf/agents`
do
     agent=${index}
     printf "\n\n Removing the docker image for $agent \n\n"
     docker kill $agent
     docker rm $agent

done

# Remove the Server
server=`head -n 1 $sdir/../conf/server`
printf "\n\n Removing the docker image for $server \n\n"
docker kill $server
docker rm $server
