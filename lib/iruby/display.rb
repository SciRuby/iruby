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
      end
    end

    private

    def add(mime, data)
      @data[mime] = MimeMagic.new(mime).text? ? data.to_s : [data.to_s].pack('m0')
    end
  end
end
