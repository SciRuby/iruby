require 'bundler'
require 'pty'
require 'expect'

class IRubyTest::IntegrationTest < IRubyTest::TestBase
  def setup
    system(*iruby_command("register", "--name=iruby-test"), out: File::NULL, err: File::NULL)
    kernel_json = File.join(ENV["JUPYTER_DATA_DIR"], "kernels", "iruby-test", "kernel.json")
    assert_path_exist kernel_json

    $expect_verbose = false # make true if you want to dump the output of iruby console

    command = iruby_command("console", "--kernel=iruby-test").map {|x| %Q["#{x}"] }
    @in, @out, pid = PTY.spawn(command.join(" "))
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

  def wait_prompt
    expect 'In ['
    expect ']:'
  end

  def test_interaction
    omit("This test too much unstable")

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
