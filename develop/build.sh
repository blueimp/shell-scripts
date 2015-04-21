#!/bin/bash

echo "Please enter the email password for the SSMTP configuration:"
read -s EMAIL_PASSWORD

cd `dirname $0`
PROJECT=$(basename $PWD)

cp php/ssmtp.conf php/ssmtp.conf.tmp
sed "s/{{EMAIL_PASSWORD}}/$EMAIL_PASSWORD/g" php/ssmtp.conf.tmp > php/ssmtp.conf

for IMAGE in `ls -d */`
do
	docker build -t $PROJECT/${IMAGE%?} $IMAGE
done

mv php/ssmtp.conf.tmp php/ssmtp.conf
