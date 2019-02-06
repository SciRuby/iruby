module IRuby
  module SessionAdapter
    class FfirzmqAdapter < BaseAdapter
      def self.load_requirements
        require 'ffi-rzmq'
      end
    end
  end
end
