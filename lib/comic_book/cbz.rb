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

    def pages = collect_pages_from_zip

    private

    def collect_pages_from_zip
      pages = []

      Zip::File.open(path) do |zipfile|
        zipfile.each do |entry|
          next unless image_file?(entry.name)

          pages << create_page_from_entry(entry)
        end
      end

      pages.sort_by &:name
    end

    def create_page_from_entry entry
      basename = File.basename entry.name

      ComicBook::Page.new entry.name, basename
    end

    def image_file? filename
      extension = File.extname filename.downcase

      ComicBook::IMAGE_EXTENSIONS.include? extension
    end
  end
end
