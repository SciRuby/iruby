module IRuby
  module Magic
    %w[ls pwd cat find env].each do|cmd|
      Class.new(Base) do
        self.class_eval do
          define_method :execute do |args, code|
            puts `#{cmd} #{args.join}`
          end

          define_method :name do
            cmd
          end
        end

      end
    end
  end
end