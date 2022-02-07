module IRuby
  module Jupyter
    class << self
      # User's default kernelspec directory is described here:
      #     https://docs.jupyter.org/en/latest/use/jupyter-directories.html
      def default_data_dir
        data_dir = ENV["JUPYTER_DATA_DIR"]
        return data_dir if data_dir

        case
        when windows?
          appdata = windows_user_appdata
          if !appdata.empty?
            File.join(appdata, 'jupyter')
          else
            jupyter_config_dir = ENV.fetch('JUPYTER_CONFIG_DIR', File.expand_path('~/.jupyter'))
            File.join(jupyter_config_dir, 'data')
          end
        when apple?
          File.expand_path('~/Library/Jupyter')
        else
          xdg_data_home = ENV.fetch('XDG_DATA_HOME', '')
          data_home = xdg_data_home[0] ? xdg_data_home : File.expand_path('~/.local/share')
          File.join(data_home, 'jupyter')
        end
      end

      def kernelspec_dir(data_dir=nil)
        data_dir ||= default_data_dir
        File.join(data_dir, 'kernels')
      end

      private

      # returns %APPDATA%
      def windows_user_appdata
        require 'fiddle/import'
        check_windows
        path = Fiddle::Pointer.malloc(2 * 300) # uint16_t[300]
        csidl_appdata = 0x001a
        case call_SHGetFolderPathW(Fiddle::NULL, csidl_appdata, Fiddle::NULL, 0, path)
        when 0
          len = (1 ... (path.size/2)).find {|i| path[2*i, 2] == "\0\0" }
          path = path.to_str(2*len).encode(Encoding::UTF_8, Encoding::UTF_16LE)
        else
          ENV.fetch('APPDATA', '')
        end
      end

      def call_SHGetFolderPathW(hwnd, csidl, hToken, dwFlags, pszPath)
        require 'fiddle/import'
        shell32 = Fiddle::Handle.new('shell32')
        func = Fiddle::Function.new(
          shell32['SHGetFolderPathW'],
          [
            Fiddle::TYPE_VOIDP,
            Fiddle::TYPE_INT,
            Fiddle::TYPE_VOIDP,
            Fiddle::TYPE_INT,
            Fiddle::TYPE_VOIDP
          ],
          Fiddle::TYPE_INT,
          Fiddle::Importer.const_get(:CALL_TYPE_TO_ABI)[:stdcall])
        func.(hwnd, csidl, hToken, dwFlags, pszPath)
      end

      def check_windows
        raise 'the current platform is not Windows' unless windows?
      end

      def windows?
        /mingw|mswin/ =~ RUBY_PLATFORM
      end

      def apple?
        /darwin/ =~ RUBY_PLATFORM
      end
    end
  end
end
