class IRubyTest::MimeTest < IRubyTest::TestBase
  sub_test_case("IRuby::Display") do
    def test_display_with_mime_type
      html = "<b>Bold Text</b>"

      obj = Object.new
      obj.define_singleton_method(:to_s) { html }

      res = IRuby::Display.display(obj, mime: "text/html")
      assert_equal({ plain: obj.inspect,       html: html },
                   { plain: res["text/plain"], html: res["text/html"] })
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
