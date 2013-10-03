module IRuby
  module Utils
    def display(obj, options={})
      Kernel.instance.display(obj, options)
    end
  end
end

include IRuby::Utils
