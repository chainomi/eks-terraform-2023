#!/bin/bash
set -xe

bucket=""
region="us-west-1"


if aws s3api head-bucket --bucket $bucket 2>&1 | grep 'Not Found' ; then
  
  #create s3 bucket
  aws s3 mb s3://$bucket --region $region

else

  echo "$bucket s3 bucket exists"

fi

