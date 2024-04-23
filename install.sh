#!/usr/bin/env bash

#
# Script to ensure environment variables are set and start the installation process.
#

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "${ARM_CLIENT_ID}" ]; then
    echo "ARM_CLIENT_ID must be set"
    exit 1
fi
if [ -z "${ARM_CLIENT_SECRET}" ]; then
    echo "ARM_CLIENT_SECRET must be set"
    exit 1
fi
if [ -z "${ARM_SUBSCRIPTION_ID}" ]; then
    echo "ARM_SUBSCRIPTION_ID must be set"
    exit 1
fi
if [ -z "${ARM_TENANT_ID}" ]; then
    echo "ARM_TENANT_ID must be set"
    exit 1
fi

terraform -chdir=$SCRIPT_DIR/terraform init
terraform -chdir=$SCRIPT_DIR/terraform apply -auto-approve
