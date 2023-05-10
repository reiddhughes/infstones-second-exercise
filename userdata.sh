#!/usr/bin/env bash

set -e

echo "Installing awscli"

apt-get -y update
apt-get install -y awscli

echo "Downloading bootstrap script"

pwd
aws s3 cp s3://is-rhughes-bucket-01/interview/bootstrap.sh bootstrap.sh

echo "Running bootstrap script"

chmod +x bootstrap.sh
./bootstrap.sh
