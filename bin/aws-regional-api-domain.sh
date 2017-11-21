#!/bin/sh

#
# Points a Route53 domain name ALIAS to a regional API endpoint in API Gateway.
#
# Requires aws and jq to be installed.
#
# Usage: ./aws-regional-api-domain domain endpoint
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

DOMAIN=${1:?}
ENDPOINT=${2:?}

# Extract the root domain:
TLD=${DOMAIN##*.}
SUBDOMAIN_PARTS=${DOMAIN%.*.$TLD}
ROOT_DOMAIN=${DOMAIN#$SUBDOMAIN_PARTS.}

# Extract the region from the endpoint domain:
# APIID.execute-api.REGION.amazonaws.com
REGION=${ENDPOINT%.amazonaws.com}
REGION=${REGION#*.execute-api.}

# Map the region to the API Gateway hosted zone ID:
# http://docs.aws.amazon.com/general/latest/gr/rande.html#apigateway_region
REGION_MAPPING=$(echo '
us-east-2=ZOJJZC49E0EPZ
us-east-1=Z1UJRXOUMOOFQ8 
us-west-1=Z2MUQ32089INYE 
us-west-2=Z2OJLYMUO9EFXC
ap-south-1=Z3VO1THU9YC4UR
ap-northeast-2=Z20JF4UZKIW1U8
ap-southeast-1=ZL327KTPIQFUL
ap-southeast-2=Z2RPCDW04V8134
ap-northeast-1=Z1YSHQZHG15GKL
ca-central-1=Z19DQILCV0OWEC
eu-central-1=Z1U9ULNL0V5AJ3
eu-west-1=ZLY8HYME6SFDD
eu-west-2=ZJ5UAJN8Y3Z2Q
sa-east-1=ZCMLWB8V5SYIT
' | grep "$REGION")

APIGW_HOSTED_ZONE_ID=${REGION_MAPPING#*=}

CHANGE_BATCH=$(printf '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "%s",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "%s",
          "HostedZoneId": "%s",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}' "$DOMAIN" "$ENDPOINT" "$APIGW_HOSTED_ZONE_ID")

get_hosted_zone_id() {
  aws route53 list-hosted-zones-by-name --dns-name "$1" --max-items 1 |
    jq -r --arg name "$1." \
    '.HostedZones[0] | select(.Name == $name) | .Id | ltrimstr("/hostedzone/")'
}

change_resource_record_sets() {
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$1" \
    --change-batch "$2"
}

HOSTED_ZONE_ID=$(get_hosted_zone_id "$ROOT_DOMAIN")
if [ ! -z "$HOSTED_ZONE_ID" ]; then
  change_resource_record_sets "$HOSTED_ZONE_ID" "$CHANGE_BATCH"
fi
