module IRuby
  module Input
    class Cancel < Widget
      needs :label

      builder :cancel do |label='Cancel'|
        add_button Cancel.new(label: label)
      end

      def widget_css
        ".iruby-cancel { margin-left: 5px; }"
      end

      def widget_js
        <<-JS
          $('.iruby-cancel').click(function(){
            $('#iruby-form').remove();
          });
        JS
      end

      def widget_html
        button(
          @label,
          type: 'button',
          :'data-dismiss' => 'modal',
          class: "btn btn-danger pull-right iruby-cancel"
        )
      end
    end
  end
end