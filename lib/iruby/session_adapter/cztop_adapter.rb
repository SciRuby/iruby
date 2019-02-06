module IRuby
  module SessionAdapter
    class CztopAdapter < BaseAdapter
      def self.load_requirements
        require 'cztop'
      end
    end
  end
end
