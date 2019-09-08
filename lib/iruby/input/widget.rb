module IRuby
  module Input
    class Widget < Erector::Widget
      needs key: nil

      def widget_js; end
      def widget_css; end
      def widget_html; end
      def content; widget_html; end

      def self.builder method, &block
        Builder.instance_eval do
          define_method method, &block
        end
      end

      def widget_join method, *args
        strings = args.map do |arg|
          arg.is_a?(String) ? arg : arg.send(method)
        end
        strings.uniq.join("\n")
      end

      def widget_display
        IRuby.display(IRuby.html(
          Erector.inline{ style raw(widget_css) }.to_html
        ))

        IRuby.display(IRuby.html(to_html))
        IRuby.display(IRuby.javascript(widget_js))
      end
    end
  end
end