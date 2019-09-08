module IRuby
  module Input
    class Label < Widget
      needs label: nil, icon: nil

      def widget_label
        div class: 'iruby-label input-group' do
          span class: 'input-group-addon' do
            text @label || to_label(@key)
          end

          yield

          if @icon
            span @icon, class: "input-group-addon"
          end
        end
      end

      private

      def to_label label
        label.to_s.tr('_',' ').capitalize
      end
    end
  end
end