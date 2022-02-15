require 'logger'

module IRuby
  class << self
    attr_accessor :logger
  end

  class MultiLogger < BasicObject
    def initialize(*loggers, level: ::Logger::DEBUG)
      @loggers = loggers
      @level = level
    end

    attr_reader :loggers

    attr_reader :level

    def level=(new_level)
      @loggers.each do |l|
        l.level = new_level
      end
      @level = new_level
    end

    def method_missing(name, *args, &b)
      @loggers.map {|x| x.respond_to?(name) && x.public_send(name, *args, &b) }.any?
    end
  end
end
