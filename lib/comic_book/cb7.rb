require 'seven_zip_ruby'
require_relative 'adapter'
require_relative 'cb7/archiver'
require_relative 'cb7/extractor'

class ComicBook
  class CB7 < Adapter
    def archive options = {}
      Archiver.new(path).archive options
    end

    def extract options = {}
      Extractor.new(path).extract options
    end

    def pages
      entries = []

      File.open(path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |reader|
          reader.entries.each do |entry|
            entries << entry.path if entry.file?
          end
        end
      end

      entries.select { image_file? it }
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
