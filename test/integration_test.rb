require 'test_helper'
require 'pty'
require 'expect'

class IRubyTest::IntegrationTest < IRubyTest::TestBase
  def setup
    $expect_verbose = false # make true if you want to dump the output of iruby console

    @in, @out, pid = PTY.spawn('bin/iruby --simple-prompt')
    @waiter = Thread.start { Process.waitpid(pid) }
    expect 'In [1]:', 30
  end

  def teardown
    @in.close
    @out.close
    @waiter.join
  end

  def write(input)
    @out.puts input
  end

  def expect(pattern, timeout = 30)
    assert @in.expect(pattern, timeout), "#{pattern} expected, but timeout"
  end

  def wait_prompt
    expect /^In \[\d+\]:/
  end

  def test_interaction
    write '"Hello, world!"'
    expect '"Hello, world!"'

    wait_prompt
    write 'puts "Hello!"'
    expect 'Hello!'

    wait_prompt
    write '12 + 12'
    expect '24'

    wait_prompt
    write 'ls'
    expect 'self.methods'
  end
end
