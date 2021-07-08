module IRubyTest
  class DisplayTest < TestBase
    def setup
      @object = Object.new
      @object.instance_variable_set(:@to_html_called, false)
      @object.instance_variable_set(:@to_markdown_called, false)
      @object.instance_variable_set(:@to_iruby_called, false)
      @object.instance_variable_set(:@to_iruby_mimebundle_called, false)

      class << @object
        attr_reader :to_html_called
        attr_reader :to_markdown_called
        attr_reader :to_iruby_called
        attr_reader :to_iruby_mimebundle_called

        def html
          "<b>html</b>"
        end

        def markdown
          "*markdown*"
        end

        def inspect
          "!!! inspect !!!"
        end
      end
    end

    def define_to_html
      class << @object
        def to_html
          @to_html_called = true
          html
        end
      end
    end

    def define_to_markdown
      class << @object
        def to_markdown
          @to_markdown_called = true
          markdown
        end
      end
    end

    def define_to_iruby
      class << @object
        def to_iruby
          @to_iruby_called = true
          ["text/html", "<b>to_iruby</b>"]
        end
      end
    end

    def define_to_iruby_mimebundle
      class << @object
        def to_iruby_mimebundle(include: [])
          @to_iruby_mimebundle_called = true
          mimes = if include.empty?
                    ["text/markdown", "application/json"]
                  else
                    include
                  end
          formats = mimes.map { |mime|
            result = case mime
                     when "text/markdown"
                       "**markdown**"
                     when "application/json"
                       %Q[{"mimebundle": "json"}]
                     end
            [mime, result]
          }.to_h
          metadata = {}
          return formats, metadata
        end
      end
    end

    def assert_iruby_display(expected)
      assert_equal(expected,
                   {
                     result: IRuby::Display.display(@object),
                     to_html_called: @object.to_html_called,
                     to_markdown_called: @object.to_markdown_called,
                     to_iruby_called: @object.to_iruby_called,
                     to_iruby_mimebundle_called: @object.to_iruby_mimebundle_called
                   })
    end

    sub_test_case("the object cannot handle all the mime types") do
      def test_display
        assert_iruby_display({
                               result: {"text/plain" => "!!! inspect !!!"},
                               to_html_called: false,
                               to_markdown_called: false,
                               to_iruby_called: false,
                               to_iruby_mimebundle_called: false
                             })
      end
    end

    sub_test_case("the object can respond to to_iruby") do
      def setup
        super
        define_to_iruby
      end

      def test_display
        assert_iruby_display({
                               result: {
                                 "text/html" => "<b>to_iruby</b>",
                                 "text/plain" => "!!! inspect !!!"
                               },
                               to_html_called: false,
                               to_markdown_called: false,
                               to_iruby_called: true,
                               to_iruby_mimebundle_called: false
                             })
      end

      sub_test_case("the object can respond to to_markdown") do
        def setup
          super
          define_to_markdown
        end

        def test_display
          assert_iruby_display({
                                 result: {
                                   "text/markdown" => "*markdown*",
                                   "text/plain" => "!!! inspect !!!"
                                 },
                                 to_html_called: false,
                                 to_markdown_called: true,
                                 to_iruby_called: false,
                                 to_iruby_mimebundle_called: false
                               })
        end
      end

      sub_test_case("the object can respond to to_html") do
        def setup
          super
          define_to_html
        end

        def test_display
          assert_iruby_display({
                                 result: {
                                   "text/html" => "<b>html</b>",
                                   "text/plain" => "!!! inspect !!!"
                                 },
                                 to_html_called: true,
                                 to_markdown_called: false,
                                 to_iruby_called: false,
                                 to_iruby_mimebundle_called: false
                               })
        end

        sub_test_case("the object can respond to to_iruby_mimebundle") do
          def setup
            super
            define_to_iruby_mimebundle
          end

          def test_display
            assert_iruby_display({
                                   result: {
                                     "text/markdown" => "**markdown**",
                                     "application/json" => %Q[{"mimebundle": "json"}],
                                     "text/plain" => "!!! inspect !!!"
                                   },
                                   to_html_called: false,
                                   to_markdown_called: false,
                                   to_iruby_called: false,
                                   to_iruby_mimebundle_called: true
                                 })
          end
        end
      end
    end
  end
end
