require 'open3'
require 'shellwords'
require 'comicinfo'
require_relative 'adapter'
require_relative 'cbr/extractor'

class ComicBook
  class CBR < Adapter
    def archive _options = {}
      raise Error, 'CBR archiving not supported (RAR is proprietary)'
    end

    def extract options = {}
      Extractor.new(path).extract options
    end

    def info
      entries = CLIHelpers.lsar_list path
      return nil unless entries.include? 'ComicInfo.xml'

      Dir.mktmpdir do |temp_dir|
        CLIHelpers.unar_extract path, temp_dir
        xml_path = File.join temp_dir, 'ComicInfo.xml'
        return nil unless File.exist? xml_path

        ComicInfo.load xml_path
      end
    end

    # Every member of the RAR archive, as Entries. RAR is read-only, so an
    # entry's path is the name lsar reports for it.
    #
    # The listing is duplicated from CLIHelpers on purpose: CLIHelpers belongs
    # to the CLI, not the library. The shared shell-out will be extracted into
    # the library proper later.
    def entries
      member_names.map { ComicBook::Entry.new it }
    end

    private

    def member_names
      output, status = Open3.capture2e lsar_binary, path

      raise Error, "lsar failed: #{output}" unless status.success?

      output.lines.drop(1).map(&:chomp).reject(&:empty?)
    end

    def lsar_binary
      case RUBY_PLATFORM
      when /darwin/ then File.expand_path 'vendor/macos/lsar', __dir__
      when /linux/  then linux_lsar
      when /mingw/  then File.expand_path 'vendor/windows/lsar', __dir__
      else
        raise Error, "Unsupported platform: #{RUBY_PLATFORM}"
      end
    end

    def linux_lsar
      return 'lsar' if system 'which lsar > /dev/null 2>&1'

      raise Error, 'lsar is not installed. Install with: sudo apt-get install unar (Ubuntu/Debian)'
    end
  end
end
