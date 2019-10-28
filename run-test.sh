#! /bin/bash

set -ex

export PYTHON=python3

ADAPTERS="cztop ffi-rzmq pyzmq"

for adapter in $ADAPTERS; do
  export IRUBY_TEST_SESSION_ADAPTER_NAME=$adapter
  bundle exec rake test TESTOPTS=-v
done
