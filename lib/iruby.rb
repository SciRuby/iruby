require 'mimemagic'
require 'multi_json'
require 'securerandom'
require 'openssl'
require 'tempfile'
require 'set'

require 'iruby/version'
require 'iruby/jupyter'
require 'iruby/kernel'
require 'iruby/backend'
require 'iruby/ostream'
require 'iruby/input'
require 'iruby/formatter'
require 'iruby/utils'
require 'iruby/display'
require 'iruby/comm'
require 'iruby/session/mixin'

begin
  require 'iruby/session/cztop'
rescue LoadError
  begin
    require 'iruby/session/ffi_rzmq'
  rescue LoadError
    begin
      require 'iruby/session/rbczmq'
    rescue LoadError
      STDERR.puts "You should install cztop, ffi_rzmq or rbczmq before running iruby notebook. See README."
    end
  end
end

require 'iruby/session'
