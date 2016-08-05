#!/bin/bash

set -u
set -e
set -v

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # current dir
cd "$DIR/bin"
tar xvfz "rocker-1.3.0_linux_amd64.tar.gz"
# Build the image
cd "$TRAVIS_BUILD_DIR"
"$DIR/bin/rocker" build
