module IRuby
  def self.convert(object, options)
    Display.convert(object, options)
  end

  def self.display(obj, options = {})
    Kernel.instance.display(obj, options)
  end

  def self.table(s, options = {})
    html(HTML.table(s, options))
  end

  def self.latex(s)
    convert(s, mime: 'text/latex')
  end

  def self.math(s)
    convert("$$#{s}$$", mime: 'text/latex')
  end

  def self.html(s)
    convert(s, mime: 'text/html')
  end

  def self.javascript(s)
    convert(s, mime: 'application/javascript')
  end

  def self.svg(s)
    convert(s, mime: 'image/svg+xml')
  end
end
