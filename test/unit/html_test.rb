require "test_config"
require "iruby/output/html"
class TestHTML < Minitest::Unit::TestCase
  def test_table
    hash = {a: 1, b:2}
    expected = '<table><tr><td>a</td><td>1</td></tr><tr><td>b</td><td>2</td></tr></table>'
    assert_equal expected.strip, IRuby::Output::HTML.table(hash).strip

    hash = [{a: 1, b:2}, {a: 2, b:4}]
    expected = '<table><tr><th>a</th><th>b</th></tr><tr><td>1</td><td>2</td></tr><tr><td>2</td><td>4</td></tr></table>'
    assert_equal expected.strip, IRuby::Output::HTML.table(hash).strip

    array = [[1,2],[2,4]]
    expected = '<table><tr><td>1</td><td>2</td><td></td></tr><tr><td>2</td><td>4</td><td></td></tr></table>'
    assert_equal expected.strip, IRuby::Output::HTML.table(array).strip


  end

end
