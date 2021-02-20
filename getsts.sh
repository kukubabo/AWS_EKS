#!/bin/bash

### SET Account Info. ##############
MASTER_ID=123456789012
IAMUSR_ID=IAMUSER_NAME
####################################

if [ $# -ne 1 ]; then
    echo "Usage: $0 123456"
    exit 1
fi

AWS_DIR=~/.aws

sed -i '4,7d' ${AWS_DIR}/credentials

aws sts get-session-token --serial-number arn:aws:iam::${MASTER_ID}:mfa/${IAMUSR_ID} --profile default --token-code $1 > ${AWS_DIR}/getsts.rst

NEW_AKI=`cat ${AWS_DIR}/getsts.rst | jq -r '.Credentials.AccessKeyId'`
NEW_SAK=`cat ${AWS_DIR}/getsts.rst | jq -r '.Credentials.SecretAccessKey'`
NEW_ST=` cat ${AWS_DIR}/getsts.rst | jq -r '.Credentials.SessionToken'`

echo "[mfa]"                              >> ${AWS_DIR}/credentials
echo "aws_access_key_id = ${NEW_AKI}"     >> ${AWS_DIR}/credentials
echo "aws_secret_access_key = ${NEW_SAK}" >> ${AWS_DIR}/credentials
echo "aws_session_token = ${NEW_ST}"      >> ${AWS_DIR}/credentials

rm ${AWS_DIR}/getsts.rst
