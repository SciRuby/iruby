require 'mimemagic'
require 'multi_json'
require 'securerandom'
require 'openssl'
require 'tempfile'
require 'set'
require 'iruby/version'
require 'iruby/kernel'
require 'iruby/backend'
require 'iruby/session'
require 'iruby/ostream'
require 'iruby/formatter'
require 'iruby/utils'
require 'iruby/display'
require 'iruby/comm'

begin
  require 'rbczmq'
rescue LoadError => e
  require 'ffi-rzmq'
  require 'iruby/session_ffi'
end
