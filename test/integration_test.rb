require 'test_helper'
require 'pty'
require 'expect'

class IntegrationTest < IRubyTest
  def setup
    $expect_verbose = false # make true if you want to dump the output of iruby console

    @in, @out, pid = PTY.spawn('bin/iruby --config=jupyter_console_config.py')
    @waiter = Thread.start { Process.waitpid(pid) }
    expect 'In [', 30
    expect '1'
    expect ']:'
  end

  def teardown
    @in.close
    @out.close
    @waiter.join
  end

  def write(input)
    @out.puts input
  end

  def expect(pattern, timeout = 10)
    assert @in.expect(pattern, timeout), "#{pattern} expected, but timeout"
  end

  def test_interaction
    write '"Hello, world!"'
    expect '"Hello, world!"'

    sleep 1
    write 'puts "Hello!"'
    expect 'Hello!'

    sleep 1
    write '12 + 12'
    expect '24'

    sleep 1
    write 'ls'
    expect 'self.methods'
  end
end
