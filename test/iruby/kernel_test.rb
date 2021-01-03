require 'test_helper'
require 'json'

module IRubyTest
  class KernelTest < TestBase
    def test_after_intialize_hooks
      ran_hook = false
      IRuby::Kernel.after_initialize do
        ran_hook = true
      end

      # may be better to put this in test/test_helper.rb
      IRuby.logger ||= Logger.new(nil)

      IRuby::Kernel.new(config_file.path)

      assert ran_hook
    ensure
      IRuby::Kernel.after_initialize_hooks.clear
    end

    def config_file
      config_file = Tempfile.new
      config_file.write({key: ""}.to_json)
      config_file.flush
      config_file
    end
  end
end
