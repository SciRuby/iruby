module IRuby
  module Input
    class Radio < Label
      needs :options

      builder :radio do |*args, **params|
        key = :radio
        key, *args = args if args.first.is_a? Symbol
        
        params[:key] = unique_key(key)
        params[:options] = args
        add_field Radio.new(**params)
      end

      def widget_js
        <<-JS
          $('.iruby-radio input').change(function(){
            var parent = $(this).closest('.iruby-radio');
            $(parent).data('iruby-value', 
              $(parent).find(':checked').val()
            );
          });
        JS
      end

      def widget_html
        params = {
          :'data-iruby-key' => @key,
          :'data-iruby-value' => @options.first,
          class: 'iruby-radio form-control'
        }
        widget_label do 
          div **params do
            @options.each do |option|
              label class: 'radio-inline' do 
                input(
                  name: @key, value: option, type: 'radio'
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