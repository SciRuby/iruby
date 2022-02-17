require "helper"
require "open3"
require "rbconfig"

require "iruby/application"

module IRubyTest
  module ApplicationTests
    class ApplicationTestBase < TestBase
      DEFAULT_KERNEL_NAME = IRuby::Application::DEFAULT_KERNEL_NAME
      DEFAULT_DISPLAY_NAME = IRuby::Application::DEFAULT_DISPLAY_NAME

      def ensure_iruby_kernel_is_installed(kernel_name=nil)
        if kernel_name
          system(*iruby_command("register", "--name=#{kernel_name}"), out: File::NULL, err: File::NULL)
        else
          system(*iruby_command("register"), out: File::NULL, err: File::NULL)
          kernel_name = DEFAULT_KERNEL_NAME
        end
        kernel_json = File.join(ENV["JUPYTER_DATA_DIR"], "kernels", kernel_name, "kernel.json")
        assert_path_exist kernel_json

        # Insert -I option to add the lib directory in the $LOAD_PATH of the kernel process
        modified_content = JSON.load(File.read(kernel_json))
        kernel_index = modified_content["argv"].index("kernel")
        modified_content["argv"].insert(kernel_index - 1, "-I#{LIB_DIR}")
        File.write(kernel_json, JSON.pretty_generate(modified_content))
      end

      def add_kernel_options(*additional_argv)
        kernel_json = File.join(ENV["JUPYTER_DATA_DIR"], "kernels", DEFAULT_KERNEL_NAME, "kernel.json")
        modified_content = JSON.load(File.read(kernel_json))
        modified_content["argv"].concat(additional_argv)
        File.write(kernel_json, JSON.pretty_generate(modified_content))
      end
    end
  end
end
