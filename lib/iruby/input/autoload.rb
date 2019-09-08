begin
  require 'erector'
rescue LoadError
  raise LoadError, <<-ERROR.gsub(/\s+/,' ')
    IRuby::Input requires the erector gem.
    `gem install erector` or add `gem 'erector'`
    it to your Gemfile to continue.
  ERROR
end

require 'iruby/input/builder'
require 'iruby/input/widget'
require 'iruby/input/form'
require 'iruby/input/label'
require 'iruby/input/field'
require 'iruby/input/popup'
require 'iruby/input/button'
require 'iruby/input/cancel'
require 'iruby/input/file'
require 'iruby/input/select'
require 'iruby/input/checkbox'
require 'iruby/input/radio'
require 'iruby/input/textarea'
require 'iruby/input/date'
require 'iruby/input/multiple'