#!/usr/bin/env ruby

$VERBOSE = true

require "bundler/setup"
require "pathname"

base_dir = Pathname.new(__dir__).parent.expand_path

lib_dir = base_dir + "lib"
test_dir = base_dir + "test"

$LOAD_PATH.unshift(lib_dir.to_s)

require_relative "helper"

ENV["TEST_UNIT_MAX_DIFF_TARGET_STRING_SIZE"] ||= "10000"
ENV["IRUBY_TEST_SESSION_ADAPTER_NAME"] ||= "ffi-rzmq"

exit Test::Unit::AutoRunner.run(true, test_dir)
