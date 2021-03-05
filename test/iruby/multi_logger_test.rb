require 'stringio'
require 'iruby/logger'

class IRubyTest::MultiLoggerTest < IRubyTest::TestBase
  def test_multilogger
    out, err = StringIO.new, StringIO.new
    logger = IRuby::MultiLogger.new(Logger.new(out), Logger.new(err))
    logger.warn 'You did a bad thing'
    assert_match 'WARN', out.string
    assert_match 'WARN', err.string
    assert_match 'bad thing', out.string
    assert_match 'bad thing', err.string
  end
end
