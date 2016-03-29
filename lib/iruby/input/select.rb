module IRuby
  module Input
    class Select < Label
      needs :options

      builder :select do |*args, **params|
        key = :select
        key, *args = args if args.first.is_a? Symbol

        key = unique_key(key)
        add_field Select.new(key: key, options: args)
      end

      def widget_css
        '.iruby-select { margin-left: 0 !important }'
      end

      def widget_js
        <<-JS
          $('.iruby-select').change(function(){
            $(this).data('iruby-value', 
              $(this).find('option:selected').text()
            );
          });
        JS
      end

      def widget_html
        widget_label do 
          div class: 'form-control' do 
            params = {
              class: 'iruby-select', 
              :'data-iruby-key' => @key,
              :'data-iruby-value' => @options.first
            }
            
            select **params do 
              @options.each {|o| option o }
            end
          end
        end
      end
    end
  end
end