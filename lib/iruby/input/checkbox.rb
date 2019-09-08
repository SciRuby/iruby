module IRuby
  module Input
    class Checkbox < Label
      needs :options, :default

      builder :checkbox do |*args, **params|
        key = :checkbox
        key, *args = args if args.first.is_a? Symbol

        params[:key] = unique_key(key)
        params[:options] = args

        params[:default] = case params[:default]
        when false, nil
          []
        when true
          [*params[:options]]
        else
          [*params[:default]]
        end

        add_field Checkbox.new(**params)
      end

      def widget_css
        <<-CSS
          .iruby-checkbox.form-control { display: inline-table; }
          .iruby-checkbox .checkbox-inline { margin: 0 15px 0 0; }
        CSS
      end

      def widget_js
        <<-JS
          $('.iruby-checkbox input').change(function(){
            var parent = $(this).closest('.iruby-checkbox');
            $(parent).data('iruby-value', []);

            $(parent).find(':checked').each(function(){
              $(parent).data('iruby-value').push($(this).val());
            });

            if ($(parent).data('iruby-value').length == 0) {
              $(parent).data('iruby-value', null);
            }
          });

          $('.iruby-checkbox input').trigger('change');
        JS
      end

      def widget_html
        params = {
          :'data-iruby-key' => @key,
          class: 'iruby-checkbox form-control'
        }
        widget_label do
          div **params do
            @options.each do |option|
              label class: 'checkbox-inline' do
                input(
                  name: @key,
                  value: option,
                  type: 'checkbox',
                  checked: @default.include?(option)
                )
                text option
              end
            end
          end
        end
      end
    end
  end
end