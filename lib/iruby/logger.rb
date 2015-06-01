require 'logger'

module IRuby
  class << self
    attr_accessor :logger
  end

  class MultiLogger < BasicObject
    attr_reader :loggers

    def initialize(*loggers)
      @loggers = loggers
    end

    def method_missing(name, *args, &b)
      @loggers.map {|x| x.respond_to?(name) && x.public_send(name, *args, &b) }.any?
    end
  end
end
