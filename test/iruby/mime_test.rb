class IRubyTest::MimeTest < IRubyTest::TestBase
  sub_test_case("IRuby::Display") do
    sub_test_case(".display") do
      sub_test_case("with mime type") do
        test("text/html") do
          html = "<b>Bold Text</b>"

          obj = Object.new
          obj.define_singleton_method(:to_s) { html }

          res = IRuby::Display.display(obj, mime: "text/html")
          assert_equal({ plain: obj.inspect,       html: html },
                       { plain: res["text/plain"], html: res["text/html"] })
        end

        test("application/javascript") do
          data = "alert('Hello World!')"
          res = IRuby::Display.display(data, mime: "application/javascript")
          assert_equal(data,
                       res["application/javascript"])
        end

        test("image/svg+xml") do
          data = '<svg height="30" width="100"><text x="0" y="15" fill="red">SVG</text></svg>'
          res = IRuby::Display.display(data, mime: "image/svg+xml")
          assert_equal(data,
                       res["image/svg+xml"])
        end
      end
    end
  end

  sub_test_case("Rendering a file") do
    def setup
      @html = "<b>Bold Text</b>"
      Dir.mktmpdir do |tmpdir|
        @file = File.join(tmpdir, "test.html")
        File.write(@file, @html)
        yield
      end
    end

    def test_display
      File.open(@file, "rb") do |f|
        res = IRuby::Display.display(f)
        assert_equal(@html, res["text/html"])
      end
    end
  end
end
