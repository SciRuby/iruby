require 'ffi-rzmq'

module IRuby
  class Session
    include SessionSerialize

    def initialize(config)
      c = ZMQ::Context.new

      connection = "#{config['transport']}://#{config['ip']}:%d"
      reply_socket = c.socket(ZMQ::XREP)
      reply_socket.bind(connection % config['shell_port'])

      pub_socket = c.socket(ZMQ::PUB)
      pub_socket.bind(connection % config['iopub_port'])

      stdin_socket = c.socket(ZMQ::XREP)
      stdin_socket.bind(connection % config['stdin_port'])

      Thread.new do
        begin
          hb_socket = c.socket(ZMQ::REP)
          hb_socket.bind(connection % config['hb_port'])
          ZMQ::Device.new(hb_socket, hb_socket)
        rescue Exception => e
          IRuby.logger.fatal "Kernel heartbeat died: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end

      @sockets = { 
        publish: pub_socket, reply: reply_socket, stdin: stdin_socket
      }
      
      @session = SecureRandom.uuid
      unless config['key'].to_s.empty? || config['signature_scheme'].to_s.empty?
        raise 'Unknown signature scheme' unless config['signature_scheme'] =~ /\Ahmac-(.*)\Z/
        @hmac = OpenSSL::HMAC.new(config['key'], OpenSSL::Digest.new($1))
      end
    end

    # Build and send a message
    def send(socket, type, content)
      idents =
        if socket == :reply && @last_recvd_msg
          @last_recvd_msg[:idents]
        else
          type == :stream ? "stream.#{content[:name]}" : type
        end
      header = {
        msg_type: type,
        msg_id:   SecureRandom.uuid,
        username: 'kernel',
        session:  @session,
        version:  '5.0'
      }
      socket = @sockets[socket]
      list = serialize(idents, header, content)
      list.each_with_index do |part, i|
        socket.send_string(part, i == list.size - 1 ? 0 : ZMQ::SNDMORE)
      end
    end

    # Receive a message and decode it
    def recv(socket)
      socket = @sockets[socket]
      msg = []
      while msg.empty? || socket.more_parts?
        begin
          frame = ''
          rc = socket.recv_string(frame)
          ZMQ::Util.error_check('zmq_msg_send', rc)
          msg << frame
        rescue
        end
      end

      @last_recvd_msg = unserialize(msg)
    end

    def recv_input 
      last_recvd_msg = @last_recvd_msg
      input = recv(:stdin)[:content]["value"]
      @last_recvd_msg = last_recvd_msg
      input
    end
  end
end
