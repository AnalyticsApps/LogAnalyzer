#!/bin/sh

sdir="`dirname \"$0\"`"
LogSearchExt_Temp="$sdir/../tmp"

setup() {

        printf "\n\n\n ****************************************************************************************************************"
        printf "\n Setting up the Support Assistant  \n"
        printf " **************************************************************************************************************** "
        printf "\n\n"

        read -p  " Provide the log collector (Case_Number.tar.gz) path : " pmrPath

        printf "\n PMR File ->  $pmrPath \n" > $sdir/../log/logDistribute.log 2>&1

        rm -rf $LogSearchExt_Temp/*
        tar -C $LogSearchExt_Temp -zxvf $pmrPath nodes.info > $sdir/../log/logDistribute.log 2>&1
        head -n 1 $LogSearchExt_Temp/nodes.info > $sdir/../conf/server
        tail -n +2 $LogSearchExt_Temp/nodes.info > $sdir/../conf/agents

        $sdir/setupCluster.sh createLogAnalyzer
        $sdir/logDistribute.sh $pmrPath


}

setup