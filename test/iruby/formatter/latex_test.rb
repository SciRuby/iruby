# frozen_string_literal: true

require 'test_helper'

module IRubyTest
  module FormatterTest
    class LaTeXTest < IRubyTest::TestBase
      def setup
        @latex = IRuby::Formatter::LaTeX
      end

      def test_vector
        assert_equal @latex.vector([1, 2, 3]),
                     '$$\left(\begin{array}{ccc} 1 & 2 & 3 \end{array}\right)$$'
      end

      # FIXME
      def test_matrix; end
    end
  end
end
