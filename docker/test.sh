#!/bin/bash

set -ex

cd /tmp/iruby
bundle install --with test --without plot
bundle exec rake test
