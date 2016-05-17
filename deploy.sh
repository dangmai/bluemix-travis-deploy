#!/bin/bash

set -u
set -e
set -v

# This script can take in a list of env vars and pass them on to cf ic run.
# We handle those here.
params=""
declare -a envs=()
while getopts "e:" opt; do
  case $opt in
    e) envs+=("$OPTARG");;
  esac
done
shift $((OPTIND -1))
if [[ ${#envs[@]} != 0 ]]; then
  for val in "${envs[@]}"; do
    params="$params -e $val"
  done
fi

# Push to Docker Hub
docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD -e $DOCKERHUB_EMAIL
docker push $REPO
docker tag $REPO registry.ng.bluemix.net/$REPO

# Download CloudFoundry BlueMix plugin
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # current dir
cd "$DIR/bin"
tar xvfz "cf-cli_6.18.0_linux_x86-64.tgz"
./cf install-plugin -f https://static-ice.ng.bluemix.net/ibm-containers-linux_x64
# Push to private repo
./cf login -u $BLUEMIX_USERNAME -p $BLUEMIX_PASSWORD -a api.ng.bluemix.net
./cf ic init
docker push registry.ng.bluemix.net/$REPO
# Restart the container
OLD_CONTAINER_NAME=`./cf ic ps | grep -oE '[^ ]+$' | grep $CONTAINER_NAME.* | cat`
NEW_CONTAINER_NAME="$CONTAINER_NAME.`date +%s`"
./cf ic run -P -m $BLUEMIX_MEMORY $params --name $NEW_CONTAINER_NAME registry.ng.bluemix.net/$REPO
sleep 30s  # sometimes we can't bind the IP to a container in a very early stage of building
if [ "$OLD_CONTAINER_NAME" != "" ]; then
  ./cf ic ip unbind $PUBLIC_IP $OLD_CONTAINER_NAME
  ./cf ic rm -f $OLD_CONTAINER_NAME
fi
./cf ic ip bind $PUBLIC_IP $NEW_CONTAINER_NAME
