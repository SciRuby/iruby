require "set"

module IRuby
  module Display
    DEFAULT_MIME_TYPE_FORMAT_METHODS = {
      "text/html" => :to_html,
      "text/markdown" => :to_markdown,
      "image/svg+xml" => :to_svg,
      "image/png" => :to_png,
      "appliation/pdf" => :to_pdf,
      "image/jpeg" => :to_jpeg,
      "text/latex" => [:to_latex, :to_tex],
      # NOTE: Do not include the entry of "application/json" because
      #       all objects can respond to `to_json` due to json library
      # "application/json" => :to_json,
      "application/javascript" => :to_javascript,
      nil => :to_iruby,
      "text/plain" => :inspect
    }.freeze

    class << self
      # @private
      def convert(obj, options)
        Representation.new(obj, options)
      end

      # @private
      def display(obj, options = {})
        obj = convert(obj, options)
        options = obj.options
        obj = obj.object

        fuzzy_mime = options[:format] # Treated like a fuzzy mime type
        unless !fuzzy_mime || String === fuzzy_mime
          raise 'Invalid argument :format'
        end

        if exact_mime = options[:mime]
          raise 'Invalid argument :mime' unless String === exact_mime
          raise 'Invalid mime type' unless exact_mime.include?('/')
        end

        data = if obj.respond_to?(:to_iruby_mimebundle)
                 render_mimebundle(obj, exact_mime, fuzzy_mime)
               else
                 {}
               end

        # Render by additional formatters
        render_by_registry(data, obj, exact_mime, fuzzy_mime)

        # Render by to_xxx methods
        default_renderers = if obj.respond_to?(:to_iruby_mimebundle)
                              # Do not use Hash#slice for Ruby < 2.5
                              {"text/plain" => DEFAULT_MIME_TYPE_FORMAT_METHODS["text/plain"]}
                            else
                              DEFAULT_MIME_TYPE_FORMAT_METHODS
                            end
        default_renderers.each do |mime, methods|
          next if mime.nil? && !data.empty? # for to_iruby

          next if mime && data.key?(mime)   # do not overwrite

          method = Array(methods).find {|m| obj.respond_to?(m) }
          next if method.nil?

          result = obj.send(method)
          case mime
          when nil # to_iruby
            case result
            when nil
              # do nothing
              next
            when Array
              mime, result = result
            else
              warn(("Ignore the result of to_iruby method of %p because " +
                    "it does not return a pair of mime-type and formatted representation") % obj)
              next
            end
          end
          data[mime] = result
        end

        # As a last resort, interpret string representation of the object
        # as the given mime type.
        if exact_mime && !data.key?(exact_mime)
          data[exact_mime] = protect(exact_mime, obj)
        end

        data
      end

      # @private
      def clear_output(wait = false)
        IRuby::Kernel.instance.session.send(:publish, :clear_output, wait: wait)
      end

      private

      def protect(mime, data)
        ascii?(mime) ? data.to_s : [data.to_s].pack('m0')
      end

      # Each of the following mime types must be a text type,
      # but mime-types library tells us it is a non-text type.
      FORCE_TEXT_TYPES = Set[
        "application/javascript",
        "image/svg+xml"
      ].freeze

      def ascii?(mime)
        if FORCE_TEXT_TYPES.include?(mime)
          true
        else
          MIME::Type.new(mime).ascii?
        end
      end

      private def render_mimebundle(obj, exact_mime, fuzzy_mime)
        data = {}
        include_mime = [exact_mime].compact
        formats, metadata = obj.to_iruby_mimebundle(include: include_mime)
        formats.each do |mime, value|
          if fuzzy_mime.nil? || mime.include?(fuzzy_mime)
            data[mime] = value
          end
        end
        data
      end

      private def render_by_registry(data, obj, exact_mime, fuzzy_mime)
        # Filter matching renderer by object type
        renderer = Registry.renderer.select { |r| r.match?(obj) }

        matching_renderer = nil

        # Find exactly matching display by exact_mime
        if exact_mime
          matching_renderer = renderer.find { |r| exact_mime == r.mime }
        end

        # Find fuzzy matching display by fuzzy_mime
        if fuzzy_mime
          matching_renderer ||= renderer.find { |r| r.mime&.include?(fuzzy_mime) }
        end

        renderer.unshift matching_renderer if matching_renderer

        # Return first render result which has the right mime type
        renderer.each do |r|
          mime, result = r.render(obj)
          next if data.key?(mime)

          if mime && result && (!exact_mime || exact_mime == mime) && (!fuzzy_mime || mime.include?(fuzzy_mime))
            data[mime] = protect(mime, result)
            break
          end
        end

        nil
      end
    end

    private def render_by_to_iruby(data, obj)
      if obj.respond_to?(:to_iruby)
        result = obj.to_iruby
        mime, rep = case result
                    when Array
                      result
                    else
                      [nil, result]
                    end
        data[mime] = rep
      end
    end

    class Representation
      attr_reader :object, :options

      def initialize(object, options)
        @object = object
        @options = options
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

    class FormatMatcher
      def initialize(&block)
        @block = block
      end

      def call(obj)
        @block.(obj)
      end

      def inspect
        "#{self.class.name}[%p]" % @block
      end
    end

    class RespondToFormatMatcher < FormatMatcher
      def initialize(name)
        super() {|obj| obj.respond_to?(name) }
        @name = name
      end

      attr_reader :name

      def inspect
        "#{self.class.name}[respond_to?(%p)]" % name
      end
    end

    class TypeFormatMatcher < FormatMatcher
      def initialize(class_block)
        super() do |obj|
          begin
            self.klass === obj
          # We have to rescue all exceptions since constant autoloading could fail with a different error
          rescue Exception
            false
          end
        end
        @class_block = class_block
      end

      def klass
        @class_block.()
      end

      def inspect
        klass = begin
                  @class_block.()
                rescue Exception
                  @class_block
                end
        "#{self.class.name}[%p]" % klass
      end
    end

    class Renderer
      attr_reader :match, :mime, :priority

      def initialize(match, mime, render, priority)
        @match = match
        @mime = mime
        @render = render
        @priority = priority
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

      def match(&block)
        @match = FormatMatcher.new(&block)
        priority 0
        nil
      end

      def respond_to(name)
        @match = RespondToFormatMatcher.new(name)
        priority 0
        nil
      end

      def type(&block)
        @match = TypeFormatMatcher.new(block)
        priority 0
        nil
      end

      def priority(p)
        @priority = p
        nil
      end

      def format(mime = nil, &block)
        renderer << Renderer.new(@match, mime, block, @priority)
        renderer.sort_by! { |r| -r.priority }

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
      format 'text/plain', &:inspect
      format 'text/latex' do |obj|
        obj.ndim == 2 ?
        LaTeX.matrix(obj, obj.shape[0], obj.shape[1]) :
          LaTeX.vector(obj.to_a)
      end
      format 'text/html' do |obj|
        HTML.table(obj.to_a)
      end

      type { NArray }
      format 'text/plain', &:inspect
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

      format_magick_image = ->(obj) do
        format = obj.format || 'PNG'
        [
          format == 'PNG' ? 'image/png' : 'image/jpeg',
          obj.to_blob {|i| i.format = format }
        ]
      end

      match do |obj|
        defined?(Magick::Image) && Magick::Image === obj ||
          defined?(MiniMagick::Image) && MiniMagick::Image === obj
      end
      format 'image', &format_magick_image

      type { Gruff::Base }
      format 'image' do |obj|
        image = obj.to_image
        format_magick_image.(obj.to_image)
      end

      match do |obj|
        defined?(Vips::Image) && Vips::Image === obj
      end
      format do |obj|
        # handles Vips::Error, vips_image_get: field "vips-loader" not found
        loader = obj.get('vips-loader') rescue nil
        if loader == 'jpegload'
          ['image/jpeg', obj.write_to_buffer('.jpg')]
        else
          # falls back to png for other/unknown types
          ['image/png', obj.write_to_buffer('.png')]
        end
      end

      type { Rubyvis::Mark }
      format 'image/svg+xml' do |obj|
        obj.render
        obj.to_svg
      end

      match { |obj| obj.respond_to?(:path) && obj.method(:path).arity == 0 && File.readable?(obj.path) }
      format do |obj|
        mime = MIME::Types.of(obj.path).first.to_s
        if mime && DEFAULT_MIME_TYPE_FORMAT_METHODS.key?(mime)
          [mime, File.read(obj.path)]
        end
      end
    end
  end
end
