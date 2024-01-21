#!/bin/bash

set -xe

secret_name="jenkins_password"
secret_key="password"
secret_value=""
region="us-west-1"

if aws secretsmanager describe-secret --secret-id $secret_name --region $region 2>&1 | grep 'ResourceNotFoundException' ; then
    # create secret
    aws secretsmanager create-secret \
        --name $secret_name \
        --region $region \
        --description "My test secret created with the CLI." \
        --secret-string "{\"$secret_key\":\"$secret_value\"}"
else
    echo "Secret named $secret_name already exists"
fi            