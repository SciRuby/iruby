require 'iruby/input/widget'
require 'iruby/input/builder'
require 'iruby/input/form'
require 'iruby/input/label'
require 'iruby/input/field'
require 'iruby/input/popup'
require 'iruby/input/button'
require 'iruby/input/cancel'
require 'iruby/input/file'
require 'iruby/input/select'
require 'iruby/input/checkbox'
require 'iruby/input/radio'
require 'iruby/input/textarea'
require 'iruby/input/date'

module IRuby
  module Input
    def input prompt='Input'
      result = form{input label: prompt}
      result[:input] unless result.nil?
    end

    def password prompt='Password'
      result = form{password label: prompt}
      result[:password] unless result.nil?
    end

    def form &block
      builder = Builder.new &block
      form = InputForm.new(
        fields: builder.fields, 
        buttons: builder.buttons
      )
      form.widget_display
      builder.process_result form.submit
    end
       
    def popup title='Input', &block
      builder = Builder.new &block
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