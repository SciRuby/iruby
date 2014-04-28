module IRuby
  class Display
    attr_reader :data

    SUPPORTED_MIMES = %w(
    text/plain
    text/html
    text/latex
    application/json
    application/javascript
    image/png
    image/jpeg
    image/svg+xml)

    def initialize(obj, options)
      @data = { 'text/plain' => obj.inspect }
      if options[:mime]
        add(options[:mime], obj)
      elsif obj.respond_to?(:to_iruby)
        add(*obj.to_iruby)
      elsif obj.respond_to?(:to_html)
        add('text/html', obj.to_html)
      elsif obj.respond_to?(:to_svg)
        obj.render if defined?(Rubyvis) && Rubyvis::Mark === obj
        add('image/svg+xml', obj.to_svg)
      elsif obj.respond_to?(:to_latex)
        add('text/latex', obj.to_latex)
      elsif defined?(Gruff::Base) && Gruff::Base === obj
        add('image/png', obj.to_blob)
      elsif (defined?(Magick::Image) && Magick::Image === obj) ||
           (defined?(MiniMagick::Image) && MiniMagick::Image === obj)
        format = obj.format || 'PNG'
        add(format == 'PNG' ? 'image/png' : 'image/jpeg', obj.to_blob {|i| i.format = format })
      elsif obj.respond_to?(:path) && File.readable?(obj.path)
        mime = MimeMagic.by_path(obj.path).to_s
        add(mime, File.read(obj.path)) if SUPPORTED_MIMES.include?(mime)
      elsif defined?(Gnuplot::Plot) && Gnuplot::Plot === obj
        Tempfile.open('plot') do |f|
          obj.terminal 'svg enhanced'
          obj.output f.path
          Gnuplot.open do |io|
            io << obj.to_gplot
            io << obj.store_datasets
          end
          add('image/svg+xml', File.read(f.path))
        end
      elsif defined?(Matrix) && Matrix === obj
        add('text/latex', format_matrix(obj, obj.row_count, obj.column_count))
      elsif defined?(GSL::Matrix) && GSL::Matrix === obj
        add('text/latex', format_matrix(obj, obj.size1, obj.size2))
      elsif defined?(GSL::Vector) && GSL::Vector === obj
        add('text/latex', format_vector(obj.to_a))
      elsif defined?(GSL::Complex) && GSL::Complex === obj
        add('text/latex', "$#{obj.re}+#{obj.im}i$")
      elsif defined?(NArray) && NArray === obj
        add('text/latex', obj.dim == 2 ?
            format_matrix(obj.transpose, obj.shape[1], obj.shape[0]) :
            format_vector(obj.to_a))
      elsif defined?(NMatrix) && NMatrix === obj
        add('text/latex', obj.dim == 2 ?
            format_matrix(obj, obj.shape[0], obj.shape[1]) :
            format_vector(obj.to_a))
      end
    end

    private

    def format_vector(v)
      "$$\\left(\\begin{array}{#{'c' * v.size}} #{v.map(&:to_s).join(' & ')} \\end{array}\\right)$$"
    end

    def format_matrix(m, row_count, column_count)
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

    def add(mime, data)
      @data[mime] = MimeMagic.new(mime).text? ? data.to_s : [data.to_s].pack('m0')
    end
  end
end
