require 'securerandom'

module IRuby
  module Input
    class InputForm < Widget
      needs :fields, buttons: []

      def widget_js
        javascript = <<-JS
          var remove = function () {
            Jupyter.notebook.kernel.send_input_reply(
              JSON.stringify({
                '#{@id = SecureRandom.uuid}': null
              })
            );
          };

          $("#iruby-form").on("remove", remove);

          $('#iruby-form').submit(function() {
            var result = {};
            $(this).off('remove', remove);

            $('[data-iruby-key]').each(function() {
              if ($(this).data('iruby-key')) {
                var value = $(this).data('iruby-value');
                if (value) {
                  result[$(this).data('iruby-key')] = value;
                }
              }
            });

            Jupyter.notebook.kernel.send_input_reply(
              JSON.stringify({'#{@id}': result})
            );

            $(this).remove();
            return false;
          });

          $('#iruby-form').keydown(function(event) {
            if (event.keyCode == 13 && !event.shiftKey) {
              $('#iruby-form').submit();
            } else if (event.keyCode == 27) {
              $('#iruby-form').remove();
            }
          });
        JS

        widget_join :widget_js, javascript, *@fields, *@buttons
      end

      def widget_css
        spacing = '#iruby-form > * { margin-bottom: 5px; }'
        widget_join :widget_css, spacing, *@fields, *@buttons
      end

      def widget_html
        form id: 'iruby-form', class: 'col-md-12' do
          @fields.each {|field| widget field}
        end
        @buttons.each {|button| widget button}
      end

      def submit
        result = MultiJson.load(Kernel.instance.session.recv_input)

        unless result.has_key? @id
          submit
        else
          Display.clear_output
          result[@id]
        end
      end
    end
  end
end