# frozen_string_literal: true

require 'test_helper'

module IRubyTest
  module FormatterTest
    class HTMLTest < IRubyTest::TestBase
      def setup
        @html = IRuby::Formatter::HTML
      end

      def test_table
        assert_equal @html.table([%w[A B C], [1, 2, 3]]),
                     '<table><tr><td>A</td><td>B</td><td>C</td></tr><tr><td>1</td><td>2</td><td>3</td></tr></table>'
      end
    end
  end
end
