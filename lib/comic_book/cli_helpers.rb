require 'English'
require 'open3'

class ComicBook
  class CLIHelpers
    class << self
      def binary_path name
        case Ruby::PLATFORM
        when /darwin/
          File.expand_path "../vendor/macos/#{name}", __FILE__
        when /linux/
          check_linux_dependency! name and name
        when /mingw/
          File.expand_path "../vendor/windows/#{name}", __FILE__
        else
          raise "Unsupported platform: #{Ruby::PLATFORM}"
        end
      end

      def check_linux_dependency! name
        return if system("which #{name} > /dev/null 2>&1")

        raise Error, "#{name} is not installed. Install it with: sudo apt-get install unar"
      end

      def lsar_list archive_path
        bin_path = binary_path 'lsar'

        output, status = Open3.capture2e(bin_path, archive_path)

        raise Error, "lsar failed: #{output}" unless status.success?

        output.lines.drop(1).map(&:chomp).reject(&:empty?)
      end

      def unar_extract archive_path, destination
        bin_path = binary_path 'unar'

        output, status = Open3.capture2e(
          bin_path,
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
