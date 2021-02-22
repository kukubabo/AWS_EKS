#!/bin/bash

# get account alias
if [ $# -eq 0 ]; then
    echo "##############################################"
    for ACCOUNT in `ls -l ~/.aws/credentials.* | awk '{print $NF}' | cut -d'.' -f3`
    do
        diff ~/.aws/credentials ~/.aws/credentials.${ACCOUNT} >/dev/null 2>&1
        #diff <(head -n 3 ~/.aws/credentials) <(head -n 3 ~/.aws/credentials.${ACCOUNT}) >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "##### List Of Account ( Current : \"${ACCOUNT}\" ) ####"
            break;
        fi
    done
    ls -l ~/.aws/credentials.* | awk '{print $NF}' | cut -d'.' -f3
    echo "##############################################"
elif [ $# -eq 1 ]; then
    ls -l ~/.aws/credentials.$1 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "\"$1\" is not exist!!"
        exit 1
    else
        cp -p ~/.aws/credentials.$1 ~/.aws/credentials
    fi
else
    echo "Usage: $0 <account alias>      (ex. acfg.sh infra)"
    exit 1
fi
