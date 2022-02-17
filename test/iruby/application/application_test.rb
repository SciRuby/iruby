require_relative "helper"

module IRubyTest::ApplicationTests
  class ApplicationTest < ApplicationTestBase
    DEFAULT_KERNEL_NAME = IRuby::Application::DEFAULT_KERNEL_NAME
    DEFAULT_DISPLAY_NAME = IRuby::Application::DEFAULT_DISPLAY_NAME

    def test_help
      out, status = Open3.capture2e(*iruby_command("--help"))
      assert status.success?
      assert_match(/--help/, out)
      assert_match(/--version/, out)
      assert_match(/^register\b/, out)
      assert_match(/^unregister\b/, out)
      assert_match(/^kernel\b/, out)
      assert_match(/^console\b/, out)
    end

    def test_version
      out, status = Open3.capture2e(*iruby_command("--version"))
      assert status.success?
      assert_match(/\bIRuby\s+#{Regexp.escape(IRuby::VERSION)}\b/, out)
    end

    def test_unknown_subcommand
      out, status = Open3.capture2e(*iruby_command("matz"))
      refute status.success?
      assert_match(/^Invalid subcommand name: matz$/, out)
      assert_match(/^Subcommands$/, out)
    end
  end
end
