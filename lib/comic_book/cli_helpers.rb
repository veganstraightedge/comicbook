require 'English'

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

      def unrar_list archive_path
        output = `unrar lb #{Shellwords.escape(archive_path)} 2>&1`
        raise Error, "unrar failed: #{output}" unless $CHILD_STATUS.success?

        output.lines.map(&:chomp).reject(&:empty?)
      end

      def unrar_extract archive_path, destination
        output = `unrar x -o+ #{Shellwords.escape(archive_path)} #{Shellwords.escape("#{destination}/")} 2>&1`
        raise Error, "unrar extraction failed: #{output}" unless $CHILD_STATUS.success?

        output
      end
    end
  end
end
