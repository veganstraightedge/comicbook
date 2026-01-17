require 'zip'
require_relative 'adapter'
require_relative 'cbz/archiver'
require_relative 'cbz/extractor'

class ComicBook
  class CBZ < Adapter
    def archive options = {}
      Archiver.new(path).archive options
    end

    def extract options = {}
      Extractor.new(path).extract options
    end

    def pages
      entries = []

      Zip::File.open(path) do |zipfile|
        zipfile.each { |entry| entries << entry.name }
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
