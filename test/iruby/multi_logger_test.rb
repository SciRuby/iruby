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

  def test_level
    out, err = StringIO.new, StringIO.new
    logger = IRuby::MultiLogger.new(Logger.new(out), Logger.new(err))

    logger.level = Logger::DEBUG
    assert_equal Logger::DEBUG, logger.level
    assert_all(logger.loggers) {|l| l.level == Logger::DEBUG }

    logger.level = Logger::INFO
    assert_equal Logger::INFO, logger.level
    assert_all(logger.loggers) {|l| l.level == Logger::INFO }
  end
end
