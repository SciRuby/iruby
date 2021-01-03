module IRuby
  module Input
    # extend the label class for the to_label helper
    class Button < Label
      needs color: :blue, js_class: 'iruby-button'

      COLORS = {
        blue: 'primary',
        gray: 'secondary',
        green: 'success',
        aqua: 'info',
        orange: 'warning',
        red: 'danger',
        none: 'link'
      }

      COLORS.default = 'primary'

      builder :button do |key='done', **params|
        params[:key] = unique_key(key)
        add_button Button.new(**params)
      end

      def widget_css
        ".#{@js_class} { margin-left: 5px; }"
      end

      def widget_js
        <<-JS
          $('.iruby-button').click(function(){
            $(this).data('iruby-value', true);
            $('#iruby-form').submit();
          });
        JS
      end

      def widget_html
        button(
          @label || to_label(@key),
          type: 'button',
          :'data-iruby-key' => @key,
          class: "btn btn-#{COLORS[@color]} pull-right #{@js_class}"
        )
      end
    end
  end
end