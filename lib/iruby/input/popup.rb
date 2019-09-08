module IRuby
  module Input
    class Popup < Widget
      needs :title, :form, buttons: []

      def widget_css
        style = '.modal-body { overflow: auto; }'
        widget_join :widget_css, style, @form, *@buttons
      end

      def widget_js
        js = <<-JS
          require(['base/js/dialog'], function(dialog) {
            var popup = dialog.modal({
              title: '#{@title.gsub("'"){"\\'"}}',
              body: '#{@form.to_html}',
              destroy: true,
              sanitize: false,
              keyboard_manager: Jupyter.notebook.keyboard_manager,
              open: function() {
                #{widget_join :widget_js, @form, *@buttons}

                var popup = $(this);

                $('#iruby-form').submit(function() {
                  popup.modal('hide');
                });

                Jupyter.notebook.keyboard_manager.disable();
              }
            });

            popup.find('.modal-footer').each(function(e) {
              $(this).append('#{@buttons.map(&:to_html).join}');
            });
          });
        JS
      end
    end
  end
end
