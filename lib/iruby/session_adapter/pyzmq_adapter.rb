module IRuby
  module SessionAdapter
    class PyzmqAdapter < BaseAdapter
      def self.load_requirements
        require 'pycall'
        @zmq = PyCall.import_module('zmq')
      rescue PyCall::PyError => error
        raise LoadError, error.message
      end
    end
  end
end
