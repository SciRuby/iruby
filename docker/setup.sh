#!/bin/bash

set -ex

apt-get update
apt-get install -y --no-install-recommends \
        libczmq-dev \
        python3 \
        python3-pip \
        python3-setuptools \
        python3-wheel

cd /tmp/iruby
bundle install --with test --without plot
pip3 install jupyter
