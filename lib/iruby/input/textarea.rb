module IRuby
  module Input
    class Textarea < Field
      needs rows: 5

      builder :textarea do |key='textarea', **params|
        params[:key] = unique_key key
        add_field Textarea.new(**params)
      end

      def widget_html
        widget_label do
          textarea(
            @default,
            rows: @rows,
            :'data-iruby-key' => @key,
            class: 'form-control iruby-field'
          )
        end
      end
    end
  end
end