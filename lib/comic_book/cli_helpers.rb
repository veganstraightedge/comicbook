class ComicBook
  class CLIHelpers
    class << self
      def platform_dir
        case RUBY_PLATFORM
        when /darwin/  then 'macos'
        when /linux/   then 'linux'
        when /mingw/   then 'windows'
        else
          raise "Unsupported platform: #{RUBY_PLATFORM}"
        end
      end

      def binary_path name
        File.expand_path("../vendor/#{platform_dir}/#{name}", __FILE__)
      end

      def run_lsar(*)
        system(binary_path('lsar'), *)
      end

      def run_unar(*)
        system(binary_path('unar'), *)
      end
    end
  end
end
