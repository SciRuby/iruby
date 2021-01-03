module IRuby
  module Input
    # autoload so that erector is not a required
    # runtime dependency of IRuby
    autoload :Builder, 'iruby/input/autoload'

    def input prompt='Input'
      result = form{input label: prompt}
      result[:input] unless result.nil?
    end

    def password prompt='Password'
      result = form{password label: prompt}
      result[:password] unless result.nil?
    end

    def form &block
      builder = Builder.new(&block)
      form = InputForm.new(
        fields: builder.fields,
        buttons: builder.buttons
      )
      form.widget_display
      builder.process_result form.submit
    end

    def popup title='Input', &block
      builder = Builder.new(&block)
      form = InputForm.new fields: builder.fields
      popup = Popup.new(
        title: title,
        form: form,
        buttons: builder.buttons
      )
      popup.widget_display
      builder.process_result form.submit
    end
  end

  extend Input
end