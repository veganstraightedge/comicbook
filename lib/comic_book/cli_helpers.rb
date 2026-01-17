require 'English'
require 'open3'

class ComicBook
  class CLIHelpers
    class << self
      def platform_dir
        case RUBY_PLATFORM
        when /darwin/  then 'macos'
        when /linux/   then 'linux'
        when /mingw/   then 'windows'
        else raise "Unsupported platform: #{RUBY_PLATFORM}"
        end
      end

      def binary_path name
        File.expand_path("../vendor/#{platform_dir}/#{name}", __FILE__)
      end

      def lsar_list archive_path
        output, status = Open3.capture2e(binary_path('lsar'), archive_path)
        raise Error, "lsar failed: #{output}" unless status.success?

        output.lines.drop(1).map(&:chomp).reject(&:empty?)
      end

      def unar_extract archive_path, destination
        output, status = Open3.capture2e(
          binary_path('unar'),
          '-o', destination,
          '-f',
          '-D',
          archive_path
        )
        raise Error, "unar extraction failed: #{output}" unless status.success?

        output
      end
    end
  end
end
