require 'iruby/message'

module IRuby
  class DisplayHook
    def initialize kernel, session, pub_socket
      @kernel = kernel
      @session = session
      @pub_socket = pub_socket
      @parent_header = {}
    end

    def __call__(obj)
      if obj.nil? || obj == []
        return
      end
      # STDERR.puts @kernel.user_ns
      # @user_ns._ = obj
      # STDERR.puts "displayhook call:"
      # STDERR.puts @parent_header.inspect
      #@pub_socket.send(msg.to_json)
      data = {}
      data['text/plain'] = obj.inspect
      content = {data: data, metadata: {}, execution_count: @kernel.execution_count}
      @session.send(@pub_socket, 'pyout', content, @parent_header)
    end

    def set_parent parent
      @parent_header = Message.extract_header(parent)
    end
  end
end
