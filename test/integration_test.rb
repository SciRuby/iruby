require 'test_helper'
require 'open3'
require 'expect'

class IntegrationTest < IRubyTest
  def setup
    @stdin, @stdout, @stderr, @process = Open3.popen3('bin/iruby')
    expect 'In [', 30
    expect '1'
    expect ']:'
  end

  def teardown
    @stdin.close
    @stdout.close
    @stderr.close
    @process.kill
  end

  def write(input)
    @stdin.puts input
  end

  def expect(pattern, timeout = 1)
    assert @stdout.expect(pattern, timeout), "#{pattern} expected"
  end

  def test_interaction
    write '"Hello, world!"'
    expect '"Hello, world!"'

    write 'puts "Hello!"'
    expect 'Hello!'

    write '12 + 12'
    expect '24'

    write 'ls'
    expect 'self.methods'
  end
end
