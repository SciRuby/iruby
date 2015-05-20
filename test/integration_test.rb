require 'test_helper'
require 'open3'

class IntegrationTest < IRubyTest
  def setup
    @stdin, @stdout, @stderr, @process = Open3.popen3('bin/iruby')
  end

  def teardown
    @stdin.close
    @stdout.close
    @stderr.close
    @process.kill
  end

  # We expect a process to print all its output at one time.
  # Otherwise this would break.
  def read
    @stdout.read_nonblock(4096)
  rescue IO::WaitReadable
    retry
  end

  def write(input)
    read # eat prompt
    @stdin.puts input
  end

  def test_hello_world
    write '"Hello, world!"'
    assert_match 'Hello, world!', read
    write 'puts "Hello, world!"'
    assert_match 'Hello, world!', read
    write '12 + 12'
    assert_match '24', read
  end

  def test_pry_functions
    write 'ls'
    assert_match 'self.methods', read
  end
end
