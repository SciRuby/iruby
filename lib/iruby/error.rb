module IRuby
  class Error < StandardError
  end

  class InvalidSubcommandError < Error
    def initialize(name, argv)
      @name = name
      @argv = argv
      super("Invalid subcommand name: #{@name}")
    end
  end
end
