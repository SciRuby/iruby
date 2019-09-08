module IRuby
  module Input
    class Field < Label
      needs default: nil, type: 'text', js_class: 'iruby-field'

      builder :input do |key='input', **params|
        params[:key] = unique_key key
        add_field Field.new(**params)
      end

      def widget_js
        <<-JS
          $('.iruby-field').keyup(function() {
            $(this).data('iruby-value', $(this).val());
          });
        JS
      end

      def widget_html
        widget_label do
          input(
            type: @type,
            :'data-iruby-key' => @key,
            class: "form-control #{@js_class}",
            value: @default
          )
        end
      end
    end
  end
end