begin
  require 'gruff'
  class Gruff::Base
    def to_iruby
      ['image/png', to_blob]
    end
  end
rescue LoadError
  # No gruff available
end
