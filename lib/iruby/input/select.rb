module IRuby
  module Input
    class Select < Label
      needs :options, :default

      builder :select do |*args, **params|
        key = :select
        key, *args = args if args.first.is_a? Symbol

        params[:key] = unique_key(key)
        params[:options] = args
        params[:default] ||= false

        unless params[:options].include? params[:default]
          params[:options] = [nil, *params[:options].compact]
        end

        add_field Select.new(**params)
      end

      def widget_css
        <<-CSS
          .iruby-select {
            min-width: 25%;
            margin-left: 0 !important;
          }
        CSS
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
              :'data-iruby-value' => @default
            }

            select **params do
              @options.each do |o|
                option o, selected: @default == o
              end
            end
          end
        end
      end
    end
  end
end