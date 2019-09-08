module IRuby
  module Input
    class Builder
      attr_reader :fields, :buttons

      def initialize &block
        @processors = {}
        @fields, @buttons = [], []
        instance_eval &block
      end

      def add_field field
        @fields << field
      end

      def add_button button
        # see bit.ly/1Tsv6x4
        @buttons.unshift button
      end

      def html &block
        add_field Class.new(Widget) {
          define_method(:widget_html) { instance_eval &block }
        }.new
      end

      def text string
        html { label string }
      end

      def password key='password', **params
        input key, **params.merge(type: 'password')
      end

      def process_result result
        unless result.nil?
          result.each_with_object({}) do |(k,v),h|
            if @processors.has_key? k
              @processors[k].call h, k, v
            else
              h[k.to_sym] = v
            end
          end
        end
      end

      private

      def process key, &block
        @processors[key.to_s] = block
      end

      def unique_key key
        @keys ||= []

        if @keys.include? key
          (2..Float::INFINITY).each do |i|
            test = "#{key}#{i}"
            break key = test unless @keys.include? test
          end
        end

        @keys << key; key
      end
    end
  end
end