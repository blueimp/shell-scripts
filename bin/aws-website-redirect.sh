#!/bin/sh

#
# Creates an S3 bucket with a website redirect rule and adds a Route53 alias.
#
# Requires aws CLI to be installed.
# Redirects to the www subdomain by default.
# Always redirects to an https URL.
#
# Usage: ./aws-website-redirect.sh [--region region] hostname [redirect_host]
#
# Copyright 2017, Sebastian Tschan
# https://blueimp.net
#
# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
#

set -e

if [ "$1" = --region ]; then
  REGION="$2"
  shift 2
else
  REGION=${AWS_DEFAULT_REGION:?}
fi

# Map the region to S3 website endpoint and S3 hosted zone ID:
# http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_website_region_endpoints
REGION_MAPPING=$(echo '
s3-website.us-east-2.amazonaws.com=Z2O1EMRO9K5GLX
s3-website-us-east-1.amazonaws.com=Z3AQBSTGFYJSTF 
s3-website-us-west-1.amazonaws.com=Z2F56UZL2M1ACD 
s3-website-us-west-2.amazonaws.com=Z3BJ6K6RIION7M
s3-website.ap-south-1.amazonaws.com=Z11RGJOFQNVJUP
s3-website.ap-northeast-3.amazonaws.com=Z2YQB5RD63NC85
s3-website.ap-northeast-2.amazonaws.com=Z3W03O7B5YMIYP
s3-website-ap-southeast-1.amazonaws.com=Z3O0J2DXBE1FTB
s3-website-ap-southeast-2.amazonaws.com=Z1WCIGYICN2BYD
s3-website-ap-northeast-1.amazonaws.com=Z2M4EHUR26P7ZW
s3-website.ca-central-1.amazonaws.com=Z1QDHH18159H29
s3-website.eu-central-1.amazonaws.com=Z21DNDUVLTQW6Q
s3-website-eu-west-1.amazonaws.com=Z1BKCTXD74EZPE
s3-website.eu-west-2.amazonaws.com=Z3GKZC51ZF0DB4
s3-website.eu-west-3.amazonaws.com=Z3R1K369G5AVDG
s3-website.eu-north-1.amazonaws.com=Z3BAZG2TWCNX0D
s3-website-sa-east-1.amazonaws.com=Z7KQH4QJS55SO
' | grep "$REGION")

BUCKET_HOSTNAME=${REGION_MAPPING%=*}
S3_HOSTED_ZONE_ID=${REGION_MAPPING#*=}

HOSTNAME=${1:?}
REDIRECT_HOSTNAME=${2:-www.$1}

# Extract the root domain:
TLD=${HOSTNAME##*.}
SUBDOMAIN_PARTS=${HOSTNAME%.*.$TLD}
ROOT_DOMAIN=${HOSTNAME#$SUBDOMAIN_PARTS.}

WEBSITE_CONFIGURATION=$(printf '{
  "RedirectAllRequestsTo": {
    "HostName": "%s",
    "Protocol": "https"
  }
}' "$REDIRECT_HOSTNAME")

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
}' "$HOSTNAME" "$BUCKET_HOSTNAME" "$S3_HOSTED_ZONE_ID")

create_bucket() {
  aws s3api create-bucket \
    --bucket "$1" \
    --region "$2" \
    --create-bucket-configuration LocationConstraint="$2"
}

put_bucket_website() {
  aws s3api put-bucket-website \
    --bucket "$1" \
    --website-configuration "$2"
}

get_hosted_zone_id() {
  aws route53 list-hosted-zones-by-name --dns-name "$1" --max-items 1 \
    --query "HostedZones[?Name == '$1.'].Id" --output text |
    sed s,/hostedzone/,,
}

change_resource_record_sets() {
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$1" \
    --change-batch "$2"
}

if ! aws s3api head-bucket --bucket "$HOSTNAME" 2> /dev/null; then
  create_bucket "$HOSTNAME" "$REGION"
fi

put_bucket_website "$HOSTNAME" "$WEBSITE_CONFIGURATION"
echo "$WEBSITE_CONFIGURATION"

HOSTED_ZONE_ID=$(get_hosted_zone_id "$ROOT_DOMAIN")
if [ -n "$HOSTED_ZONE_ID" ]; then
  change_resource_record_sets "$HOSTED_ZONE_ID" "$CHANGE_BATCH"
fi
