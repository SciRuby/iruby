module IRuby
  module Input
    class Label < Widget
      needs label: nil

      def widget_label
        label = @label || to_label(@key)
        div class: 'iruby-label input-group' do
          span label, class: 'input-group-addon'
          yield
        end
      end

      private

      def to_label label
        label.to_s.tr('_',' ').capitalize
      end
    end
  end
end