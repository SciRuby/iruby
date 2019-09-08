module IRuby
  module Input
    class Multiple < Label
      needs :options, :default, size: nil

      builder :multiple do |*args, **params|
        key = :multiple
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

        add_field Multiple.new(**params)
      end

      def widget_css
        <<-CSS
          .iruby-multiple {
            display: table;
            min-width: 25%;
          }
          .form-control.iruby-multiple-container {
            display: table;
          }
        CSS
      end

      def widget_js
        <<-JS
          $('.iruby-multiple').change(function(){
            var multiple = $(this);
            multiple.data('iruby-value', []);

            multiple.find(':selected').each(function(){
              multiple.data('iruby-value').push($(this).val());
            });

            if (multiple.data('iruby-value').length == 0) {
              multiple.data('iruby-value', null);
            }
          });

          $('.iruby-multiple').trigger('change');
        JS
      end

      def widget_html
        widget_label do
          div class: 'form-control iruby-multiple-container' do
            params = {
              size: @size,
              multiple: true,
              class: 'iruby-multiple',
              :'data-iruby-key' => @key
            }

            select **params do
              @options.each do |o|
                option o, selected: @default.include?(o)
              end
            end
          end
        end
      end
    end
  end
end