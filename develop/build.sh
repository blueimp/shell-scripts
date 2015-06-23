#!/bin/bash

cd `dirname $0`
PROJECT=$(basename $PWD)

for IMAGE in `ls -d */`
do
	docker build -t $PROJECT/${IMAGE%?} $IMAGE
done
