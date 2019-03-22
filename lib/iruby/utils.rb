module IRuby
  module Utils
    def convert(object, options)
      Display.convert(object, options)
    end

    def display(obj, options = {})
      Kernel.instance.session.send(:publish, :display_data,
                                   data: Display.display(obj, options),
                                   metadata: {}) unless obj.nil?
    end

    def table(s, **options)
      html(HTML.table(s, options))
    end

    def latex(s)
      convert(s, mime: 'text/latex')
    end
    alias tex latex

    def math(s)
      convert("$$#{s}$$", mime: 'text/latex')
    end

    def html(s)
      convert(s, mime: 'text/html')
    end

    def javascript(s)
      convert(s, mime: 'application/javascript')
    end

    def svg(s)
      convert(s, mime: 'image/svg+xml')
    end
  end

  extend Utils
end
