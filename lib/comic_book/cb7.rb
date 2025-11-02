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

    def pages = collect_pages_from_7z

    private

    def collect_pages_from_7z
      pages = []

      File.open(path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          szr.entries.each do |entry|
            next unless entry.file? && image_file?(entry.path)

            pages << create_page_from_entry(entry)
          end
        end
      end

      pages.sort_by(&:name)
    end

    def create_page_from_entry entry
      basename = File.basename(entry.path)

      ComicBook::Page.new entry.path, basename
    end

    def image_file? filename
      extension = File.extname(filename.downcase)

      ComicBook::IMAGE_EXTENSIONS.include? extension
    end
  end
end
