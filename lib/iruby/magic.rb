module IRuby

  module Magic

    class Base

      class << self
        def subclasses
          @subclasses ||= []
        end

        def inherited(base) #:nodoc:
          super
          subclasses << base if !base.name || base.name !~ /Base$/
        end

      end

      def initialize(backend)
        @backend = backend
      end

      def name
        self.class.name.split('::')[-1].downcase
      end

      def execute(args, code)

      end

      def eval(code)
        TOPLEVEL_BINDING.eval(code)
      end

    end
  end

  Dir[File.dirname(__FILE__) + '/magic/*.rb'].each {|magic_file| require magic_file }

end