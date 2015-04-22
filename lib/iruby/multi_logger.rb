require "logger"

module IRuby
  class << self
    attr_accessor :logger
  end

  class MultiLogger < BasicObject
    def initialize(*loggers)
      @loggers = loggers.map { |e| ::Logger.new(e) }
    end

    def method_missing(name, *args, &b)
      @loggers.map { |e| e.respond_to?(name) && e.public_send(name, *args, &b) }.any?
    end
  end
end
