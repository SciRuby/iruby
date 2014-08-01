module IRuby
  class Display
    module Helper
      def latex_vector(v)
        x = 'c' * v.size
        y = v.map(&:to_s).join(' & ')
        "$$\\left(\\begin{array}{#{x}} #{y} \\end{array}\\right)$$"
      end

      def latex_matrix(m, row_count, column_count)
        s = "$$\\left(\\begin{array}{#{'c' * column_count}}\n"
        (0...row_count).each do |i|
          s << '  ' << m[i,0].to_s
          (1...column_count).each do |j|
            s << '&' << m[i,j].to_s
          end
          s << "\\\\\n"
        end
        s << "\\end{array}\\right)$$"
      end
    end

    include Helper

    attr_reader :match, :formats

    def initialize(match)
      @match, @formats = match, {}
    end

    def add(mime, block)
      @formats[mime] = block
    end

    def self.data_add(data, mime, value)
      data[mime] = MimeMagic.new(mime).text? ? value.to_s : [value.to_s].pack('m0')
    end

    def self.display(obj, options = {})
      mime = options[:mime]
      data = { 'text/plain' => obj.inspect }
      if options[:mime]
      else
      end
      display = Registry.displays.find do |d|
        begin
          d.match.call(obj)
        rescue NameError
          false
        end
      end
      if display
        formats = display.formats.to_a
        if mime
          format = display.formats[mime]
          format = [mime, format] if format
          format ||= display.formats.find {|m| mime === m }
          formats.unshift format
        end
        formats.each do |format_mime, format|
          result = display.instance_exec(obj, &format)
          result_mime = format_mime
          result_mime, result = result if Array === result
          if !mime || mime === result_mime
            data_add(data, result_mime, result)
            break
          end
        end
      end
      data_add(data, mime, obj) if mime && !data.any? {|m,_| mime === m }
      data
    end

    module Registry
      extend self

      def displays
        @displays ||= []
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
        displays << Display.new(block)
      end

      def respond_to(name)
        match {|obj| obj.respond_to?(name) }
      end

      def type(&block)
        match {|obj| block.call === obj }
      end

      def display(mime = nil, &block)
        displays.last.add(mime, block)
      end

      type { NMatrix }
      display 'text/latex' do |obj|
        obj.dim == 2 ?
         latex_matrix(obj, obj.shape[0], obj.shape[1]) :
          latex_vector(obj.to_a)
      end

      type { NArray }
      display 'text/latex' do |obj|
        obj.dim == 2 ?
        latex_matrix(obj.transpose, obj.shape[1], obj.shape[0]) :
          latex_vector(obj.to_a)
      end

      type { Matrix }
      display 'text/latex' do |obj|
        latex_matrix(obj, obj.row_count, obj.column_count)
      end

      type { GSL::Matrix }
      display 'text/latex' do |obj|
        latex_matrix(obj, obj.size1, obj.size2)
      end

      type { GSL::Vector }
      display 'text/latex' do |obj|
        latex_vector(obj.to_a)
      end

      type { GSL::Complex }
      display 'text/latex' do |obj|
        "$#{obj.re}+#{obj.im}i$"
      end

      type { Gnuplot::Plot }
      display 'image/svg+xml' do |obj|
        Tempfile.open('plot') do |f|
          obj.terminal 'svg enhanced'
          obj.output f.path
          Gnuplot.open do |io|
            io << obj.to_gplot
            io << obj.store_datasets
          end
          File.read(f.path)
        end
      end

      match {|obj| Magick::Image === obj || MiniMagick::Image === obj }
      display 'image' do |obj|
        format = obj.format || 'PNG'
        [format == 'PNG' ? 'image/png' : 'image/jpeg', obj.to_blob {|i| i.format = format }]
      end

      type { Gruff::Base }
      display 'image/png' do |obj|
        obj.to_blob
      end

      respond_to :to_html
      display 'text/html' do |obj|
        obj.to_html
      end

      respond_to :to_latex
      display 'text/latex' do |obj|
        obj.to_latex
      end

      respond_to :to_svg
      display 'text/svg' do |obj|
        obj.to_svg
      end

      respond_to :to_svg
      display 'image/svg+xml' do |obj|
        obj.render if defined?(Rubyvis) && Rubyvis::Mark === obj
        obj.to_svg
      end

      respond_to :to_iruby
      display do |obj|
        obj.to_iruby
      end

      match {|obj| obj.respond_to?(:path) && File.readable?(obj.path) }
      display do |obj|
        mime = MimeMagic.by_path(obj.path).to_s
        [mime, File.read(obj.path)] if SUPPORTED_MIMES.include?(mime)
      end
    end
  end
end
