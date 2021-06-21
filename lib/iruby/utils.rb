module IRuby
  module Utils
    def convert(object, options)
      Display.convert(object, options)
    end

    # Display the object
    def display(obj, options = {})
      Kernel.instance.session.send(:publish, :display_data,
                                   data: Display.display(obj, options),
                                   metadata: {}) unless obj.nil?
      # The next `nil` is necessary to prevent unintentional displaying
      # the result of Session#send
      nil
    end

    # Clear the output area
    def clear_output(wait=false)
      Display.clear_output(wait)
    end

    # Format the given object into HTML table
    def table(s, **options)
      html(HTML.table(s, **options))
    end

    # Treat the given string as LaTeX text
    def latex(s)
      convert(s, mime: 'text/latex')
    end
    alias tex latex

    # Format the given string of TeX equation into LaTeX text
    def math(s)
      convert("$$#{s}$$", mime: 'text/latex')
    end

    # Treat the given string as HTML
    def html(s)
      convert(s, mime: 'text/html')
    end

    # Treat the given string as JavaScript code
    def javascript(s)
      convert(s, mime: 'application/javascript')
    end

    # Treat the given string as SVG text
    def svg(s)
      convert(s, mime: 'image/svg+xml')
    end
  end

  extend Utils
end
