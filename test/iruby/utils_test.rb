module IRubyTest
  class UtilsTest < TestBase
    sub_test_case("IRuby.table") do
      def setup
        @data = {
          X: [ 1, 2, 3 ],
          Y: [ 4, 5, 6 ]
        }
      end
      sub_test_case("without header: option") do
        def test_table
          result = IRuby.table(@data)
          assert_include(result.object, "<th>X</th>")
        end
      end

      sub_test_case("with header: false") do
        def test_table
          result = IRuby.table(@data, header: false)
          assert_not_include(result.object, "<th>X</th>")
        end
      end
    end
  end
end
