module IRuby
  module Input
    class Date < Field
      needs js_class: 'iruby-date'

      builder :date do |key='date', **params|
        params[:key] = unique_key key
        add_field Date.new(**params)
      end

      def widget_css
        '#ui-datepicker-div { z-index: 2000; }'
      end

      def widget_js 
        <<-JS
          $('.iruby-date').datepicker({
            onClose: function(date) {
              $('.iruby-date').data('iruby-value', date);
            }  
          });
        JS
      end
    end
  end
end