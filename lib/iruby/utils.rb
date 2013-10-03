module IRuby
  class IRubyObject
    attr_reader :data, :mime

    def initialize(mime, data)
      @mime, @data = mime, data
    end

    def to_iruby
      [@mime, @data]
    end
  end

  def self.display(obj, options={})
    Kernel.instance.display(obj, options)
  end

  def self.latex(s)
    IRubyObject.new('text/latex', s)
  end

  def self.math(s)
    IRubyObject.new('text/latex', "$$#{s}$$")
  end

  def self.html(s)
    IRubyObject.new('text/html', s)
  end
end
