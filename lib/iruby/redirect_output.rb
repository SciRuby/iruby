module IRuby
  module RedirectOutput 
    # redirects all STDOUT and STDERR generated in the
    # given block to its respective IRuby::OStream
    def redirect_output &block
      ios = [
        [STDOUT, STDOUT.dup, @stdout, IO.pipe], 
        [STDERR, STDERR.dup, @stderr, IO.pipe]
      ]

      # a hash from read handle to write handles
      handles = ios.map do |real,dup,iruby,(read,write)|
        read.sync = write.sync = true
        real.reopen write 
        [read,iruby]
      end.to_h

      thread = Thread.new do 
        until handles.empty?
          reads, writes, errors = IO.select(handles.keys)

          reads.each do |read|
            if read.eof? 
              handles.delete read
            else
              handles[read].write read.readpartial(4096)
            end
          end
        end
      end

      begin
        yield
      ensure
        ios.each do |real,dup,iruby,(read,write)|
          write.close
          real.reopen dup
        end
        thread.join
      end
    end
  end
end