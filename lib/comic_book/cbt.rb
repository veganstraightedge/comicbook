require 'rubygems/package'
require_relative 'adapter'
require_relative 'cbt/archiver'
require_relative 'cbt/extractor'

class ComicBook
  class CBT < Adapter
    def archive options = {}
      Archiver.new(path).archive options
    end

    def extract options = {}
      Extractor.new(path).extract options
    end

    def pages = collect_pages

    private

    def collect_pages
      entries = []

      File.open(path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |reader|
          reader.each do |entry|
            entries << entry.full_name if entry.file?
          end
        end
      end

      entries.select { |entry| image_file?(entry) }
             .map { |entry| create_page_from_entry(entry) }
             .sort_by(&:name)
    end

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
