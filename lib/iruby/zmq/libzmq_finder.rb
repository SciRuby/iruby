require "fiddle"
require "open3"
require "rbconfig"

module IRuby
  module ZMQ
    module LibZMQFinder
      def self.find_libzmq
        name_candidates = list_candidates

        # 1. Try IRUBY_LIBZMQ environment variable
        if ENV.key?("IRUBY_LIBZMQ")
          begin
            Fiddle.dlopen(ENV["IRUBY_LIBZMQ"]).close
          rescue Fiddle::LoadError
            warn "WARNING: Unable to load libzmq specified in IRUBY_LIBZMQ"
          else
            return ENV["IRUBY_LIBZMQ"]
          end
        end

        # 2. Try IRUBY_LIBZMQ_PREFIX environment variable
        if ENV.key?("IRUBY_LIBZMQ_PREFIX")
          prefix = ENV["IRUBY_LIBZMQ_PREFIX"]
          if File.directory?(prefix)
            libdir = File.join(prefix, "lib")
            path = find_libzmq_at(name_candidates, libdir)
            return path if path
            warn "WARNING: Unable to load libzmq in ${IRUBY_LIBZMQ_PREFIX}/lib"
          else
            warn "WARNING: IRUBY_LIBZMQ_PREFIX is specified, but it is not a directory"
          end
        end

        # 3. Try Homebrew if available
        path = find_libzmq_in_homebrew(name_candidates)
        return path if path

        # 4. Search in the default library path
        return name_candidates.find {|fn| loadable?(fn) }
      end

      def self.find_libzmq_at(name_candidates, dir)
        name_candidates.each do |name|
          path = File.join(dir, name)
          next unless File.file?(path)
          return path if loadable?(path)
        end
        return nil
      end

      def self.find_libzmq_in_homebrew(name_candidates)
        begin
          out, status = Open3.capture2("brew", "--prefix", "zmq", err: File::NULL)
          return nil unless status.success?
          libdir = File.join(out.chomp, "lib")
          File.directory?(libdir) && find_libzmq_at(name_candidates, libdir)
        rescue Errno::ENOENT
          return nil
        end
      end

      def self.loadable?(filename)
        begin
          $stderr.puts "loadable?(%p)" % filename
          Fiddle.dlopen(filename).close
        rescue Fiddle::DLError
          false
        else
          true
        end
      end

      def self.list_candidates
        name_stem = ["zmq"]
        name_prefix = ["lib"]
        name_ext = [".#{RbConfig::CONFIG["SOEXT"]}"]

        # Assume version 4.x
        version_suffix = [".5", ""]

        # Examine non-"lib"-prefixed name on Windows
        name_prefix << "" if /mswin|mingw|msys/ =~ RUBY_PLATFORM

        if /darwin|mac os/ =~ RUBY_PLATFORM
          name_prefix.product(name_stem, version_suffix, name_ext).map(&:join)
        else
          name_prefix.product(name_stem, name_ext, version_suffix).map(&:join)
        end
      end
    end
  end
end
