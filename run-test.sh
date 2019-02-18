#! /bin/bash

set -ex

# ADAPTERS="cztop rbczmq ffi-rzmq pyzmq"
ADAPTERS="cztop rbczmq ffi-rzmq"

for adapter in $ADAPTERS; do
  export IRUBY_TEST_SESSION_ADAPTER_NAME=$adapter
  bundle exec rake test TESTOPTS=-v
done
