module IRuby
  module Display
    class << self
      def convert(obj, options)
        Representation.new(obj, options)
      end

      def display(obj, options = {})
        obj = convert(obj, options)
        options = obj.options
        obj = obj.object

        fuzzy_mime = options[:format] # Treated like a fuzzy mime type
        raise 'Invalid argument :format' unless !fuzzy_mime || String === fuzzy_mime
        if exact_mime = options[:mime]
          raise 'Invalid argument :mime' unless String === exact_mime
          raise 'Invalid mime type' unless exact_mime.include?('/')
        end

        data = {}

        # Render additional representation
        render(data, obj, exact_mime, fuzzy_mime)

        # IPython always requires a text representation
        render(data, obj, 'text/plain', nil) unless data['text/plain']

        # As a last resort, interpret string representation of the object
        # as the given mime type.
        data[exact_mime] = protect(exact_mime, obj) if exact_mime && !data.any? {|m,_| exact_mime == m }

        data
      end

      def clear_output(wait=false)
        IRuby::Kernel.instance.session.send(:publish, :clear_output, {wait: wait})
      end

      private

      def protect(mime, data)
        MimeMagic.new(mime).text? ? data.to_s : [data.to_s].pack('m0')
      end

      def render(data, obj, exact_mime, fuzzy_mime)
        # Filter matching renderer by object type
        renderer = Registry.renderer.select {|r| r.match?(obj) }

        matching_renderer = nil

        # Find exactly matching display by exact_mime
        matching_renderer = renderer.find {|r| exact_mime == r.mime } if exact_mime

        # Find fuzzy matching display by fuzzy_mime
        matching_renderer ||= renderer.find {|r| r.mime && r.mime.include?(fuzzy_mime) } if fuzzy_mime

        renderer.unshift matching_renderer if matching_renderer

        # Return first render result which has the right mime type
        renderer.each do |r|
          mime, result = r.render(obj)
          if mime && result && (!exact_mime || exact_mime == mime) && (!fuzzy_mime || mime.include?(fuzzy_mime))
            data[mime] = protect(mime, result)
            break
          end
        end

        nil
      end
    end

    class Representation
      attr_reader :object, :options

      def initialize(object, options)
        @object, @options = object, options
      end

      class << self
        alias old_new new

        def new(obj, options)
          options = { format: options } if String === options
          if Representation === obj
            options = obj.options.merge(options)
            obj = obj.object
          end
          old_new(obj, options)
        end
      end
    end

    class Renderer
      attr_reader :match, :mime, :render, :priority

      def initialize(match, mime, render, priority)
        @match, @mime, @render, @priority = match, mime, render, priority
      end

      def match?(obj)
        @match.call(obj)
      end

      def render(obj)
        result = @render.call(obj)
        Array === result ? result : [@mime, result]
      end
    end

    module Registry
      extend self

      def renderer
        @renderer ||= []
      end

      SUPPORTED_MIMES = %w(
        text/plain
        text/html
        text/latex
        application/json
        application/javascript
        image/png
        image/jpeg
        image/svg+xml)

      def match(&block)
        @match = block
        priority 0
        nil
      end

      def respond_to(name)
        match {|obj| obj.respond_to?(name) }
      end

      def type(&block)
        match do |obj|
          begin
            block.call === obj
          # We have to rescue all exceptions since constant autoloading could fail with a different error
          rescue Exception
          rescue #NameError
            false
          end
        end
      end

      def priority(p)
        @priority = p
        nil
      end

      def format(mime = nil, &block)
        renderer << Renderer.new(@match, mime, block, @priority)
        renderer.sort_by! {|r| -r.priority }

        # Decrease priority implicitly for all formats
        # which are added later for a type.
        # Overwrite with the `priority` method!
        @priority -= 1
        nil
      end

      type { NMatrix }
      format 'text/latex' do |obj|
        obj.dim == 2 ?
         LaTeX.matrix(obj, obj.shape[0], obj.shape[1]) :
          LaTeX.vector(obj.to_a)
      end

      type { Numo::NArray }
      format 'text/latex' do |obj|
        obj.ndim == 2 ?
        LaTeX.matrix(obj, obj.shape[0], obj.shape[1]) :
          LaTeX.vector(obj.to_a)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { NArray }
      format 'text/latex' do |obj|
        obj.dim == 2 ?
        LaTeX.matrix(obj.transpose(1, 0), obj.shape[1], obj.shape[0]) :
          LaTeX.vector(obj.to_a)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { Matrix }
      format 'text/latex' do |obj|
        LaTeX.matrix(obj, obj.row_size, obj.column_size)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { GSL::Matrix }
      format 'text/latex' do |obj|
        LaTeX.matrix(obj, obj.size1, obj.size2)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { GSL::Vector }
      format 'text/latex' do |obj|
        LaTeX.vector(obj.to_a)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { GSL::Complex }
      format 'text/latex' do |obj|
        "$#{obj.re}+#{obj.im}\\imath$"
      end

      type { Complex }
      format 'text/latex' do |obj|
        "$#{obj.real}+#{obj.imag}\\imath$"
      end

      type { Gnuplot::Plot }
      format 'image/svg+xml' do |obj|
        Tempfile.open('plot') do |f|
          terminal = obj['terminal'].to_s.split(' ')
          terminal[0] = 'svg'
          terminal << 'enhanced' unless terminal.include?('noenhanced')
          obj.terminal terminal.join(' ')
          obj.output f.path
          Gnuplot.open do |io|
            io << obj.to_gplot
            io << obj.store_datasets
          end
          File.read(f.path)
        end
      end

      type { GnuplotRB::Plottable }
      format 'image/svg+xml' do |obj|
        options = obj.term ? obj.term[1] : {}
        obj.to_svg(options)
      end

      match do |obj|
        defined?(Magick::Image) && Magick::Image === obj ||
        defined?(MiniMagick::Image) && MiniMagick::Image === obj
      end
      format 'image' do |obj|
        format = obj.format || 'PNG'
        [format == 'PNG' ? 'image/png' : 'image/jpeg', obj.to_blob {|i| i.format = format }]
      end

      type { Gruff::Base }
      format 'image/png' do |obj|
        obj.to_blob
      end

      respond_to :to_html
      format 'text/html' do |obj|
        obj.to_html
      end

      respond_to :to_latex
      format 'text/latex' do |obj|
        obj.to_latex
      end

      respond_to :to_tex
      format 'text/latex' do |obj|
        obj.to_tex
      end

      respond_to :to_javascript
      format 'text/javascript' do |obj|
        obj.to_javascript
      end

      respond_to :to_svg
      format 'image/svg+xml' do |obj|
        obj.render if defined?(Rubyvis) && Rubyvis::Mark === obj
        obj.to_svg
      end

      respond_to :to_iruby
      format do |obj|
        obj.to_iruby
      end

      match {|obj| obj.respond_to?(:path) && File.readable?(obj.path) }
      format do |obj|
        mime = MimeMagic.by_path(obj.path).to_s
        [mime, File.read(obj.path)] if SUPPORTED_MIMES.include?(mime)
      end

      type { Object }
      priority -1000
      format 'text/plain' do |obj|
        obj.inspect
      end
    end
  end
end
