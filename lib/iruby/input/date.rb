module IRuby
  module Input
    class Date < Field
      needs js_class: 'iruby-date', icon: '📅'

      builder :date do |key='date', **params|
        params[:default] ||= false
        params[:key] = unique_key key

        if params[:default].is_a? Time
          params[:default] = params[:default].strftime('%m/%d/%Y')
        end

        add_field Date.new(**params)

        process params[:key] do |result,key,value|
          result[key.to_sym] = Time.strptime(value,'%m/%d/%Y')
        end
      end

      def widget_css
        '#ui-datepicker-div { z-index: 2000 !important; }'
      end

      def widget_js
        <<-JS
          $('.iruby-date').datepicker({
            dateFormat: 'mm/dd/yy',
            onClose: function(date) {
              $(this).data('iruby-value', date);
            }
          });
        JS
      end
    end
  end
end
