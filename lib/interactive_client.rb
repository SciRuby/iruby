require File.expand_path('../console', __FILE__)

class InteractiveClient#(object)
  def initialize(session, request_socket, sub_socket)
    @session = session
    @request_socket = request_socket
    @sub_socket = sub_socket
    @console = Console.new(nil, '<zmq-console>', @session, @request_socket, @sub_socket)
  end

  def interact
    @console.interact
  end

  def runcode(code)
    @console.runcode(code)
  end
end

