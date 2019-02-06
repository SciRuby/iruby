module IRuby
  module SessionAdapter
    class RbczmqAdapter < BaseAdapter
      def self.load_requirements
        require 'rbczmq'
      end
    end
  end
end
