module Kernel
  alias_method :require_without_iruby, :require

  def require(name)
    result = require_without_iruby(name)
    apply_iruby_patches
    result
  end

  def apply_iruby_patches
    if defined?(Gruff::Base) && Gruff::Base.instance_methods.include?(:to_iruby)
      Gruff::Base.class_eval do
        def to_iruby
          ['image/png', to_blob]
        end
      end
    end

    if defined?(RMagick::Base) && RMagick::Base.instance_methods.include?(:to_iruby)
      RMagick::Base.class_eval do
        def to_iruby
          ['image/png', to_blob]
        end
      end
    end
  end
end
