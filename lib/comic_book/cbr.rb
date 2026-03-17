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

    def pages
      CLIHelpers.lsar_list(path)
                .select { image_file? it }
                .map    { create_page_from_entry it }
                .sort_by(&:name)
    end

    private

    def create_page_from_entry entry
      basename = File.basename entry

      ComicBook::Page.new entry, basename
    end

    def image_file? filename
      extension = File.extname filename.downcase

      ComicBook::IMAGE_EXTENSIONS.include? extension
    end
  end
end
