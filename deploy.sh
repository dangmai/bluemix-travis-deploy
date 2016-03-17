#!/bin/bash

set -u
set -e
set -v

DOWNLOAD_DIR="/tmp"
mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR
# Download Rocker
curl -O -L https://github.com/grammarly/rocker/releases/download/1.1.2/rocker-1.1.2-linux_amd64.tar.gz
tar xvfz rocker-1.1.2-linux_amd64.tar.gz
# Build the image
cd $TRAVIS_BUILD_DIR
$DOWNLOAD_DIR/rocker build
# Push to Docker Hub
docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD -e $DOCKERHUB_EMAIL
docker push $REPO
docker tag $REPO registry.ng.bluemix.net/$REPO
# Download CloudFoundry CLI tool & BlueMix plugin
cd $DOWNLOAD_DIR
curl -o cf.tgz -L 'https://cli.run.pivotal.io/stable?release=linux64-binary&version=6.16.1&source=github-rel'
tar xvfz cf.tgz
./cf install-plugin -f https://static-ice.ng.bluemix.net/ibm-containers-linux_x64
# Push to private repo
./cf login -u $BLUEMIX_USERNAME -p $BLUEMIX_PASSWORD -a api.ng.bluemix.net
./cf ic init
docker push registry.ng.bluemix.net/$REPO
# Restart the container
OLD_CONTAINER_NAME=`./cf ic ps | grep -oE '[^ ]+$' | grep $CONTAINER_NAME.* | cat`
NEW_CONTAINER_NAME="$CONTAINER_NAME.`date +%s`"
./cf ic run -p 80 -m $BLUEMIX_MEMORY --name $NEW_CONTAINER_NAME registry.ng.bluemix.net/$REPO
sleep 30s  # sometimes we can't bind the IP to a container in a very early stage of building
if [ "$OLD_CONTAINER_NAME" != "" ]; then
  ./cf ic ip unbind $PUBLIC_IP $OLD_CONTAINER_NAME
  ./cf ic rm -f $OLD_CONTAINER_NAME
fi
./cf ic ip bind $PUBLIC_IP $NEW_CONTAINER_NAME
