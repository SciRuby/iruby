require 'data_uri'

module IRuby
  module Input
    class File < Label
      builder :file do |key='file', **params|
        key = unique_key key
        add_field File.new(key: key, **params)

        # tell the builder to process files differently
        process key do |result,key,value|
          uri = URI::Data.new value['data']

          # get rid of Chrome's silly path
          name = value['name'].sub('C:\\fakepath\\','')

          result[key.to_sym] = {
            name: name,
            data: uri.data,
            content_type: uri.content_type
          }
        end
      end

      def widget_js
        <<-JS
          $('.iruby-file').change(function() {
            var input = $(this);

            $.grep($(this).prop('files'), function(file) {
              var reader = new FileReader();

              reader.addEventListener("load", function(event) {
                input.data('iruby-value', {
                  name: input.val(),
                  data: event.target.result
                });
              });

              reader.readAsDataURL(file);
            });
          });
        JS
      end

      def widget_html
        widget_label do
          input(
            type: 'file',
            :'data-iruby-key' => @key,
            class: 'form-control iruby-file'
          )
        end
      end
    end
  end
end