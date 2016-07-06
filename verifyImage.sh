#!/bin/bash

if [ $# -ne 1 ]; then
	echo "ERROR: invalid argument count. Got $# arguments; should be exactly 1"
	exit 1
fi

echo "Pulling $1"
docker pull $1

if [ $? -eq 0 ]; then
	echo "ERROR: Docker image $1 already exists"
	exit 1
fi
