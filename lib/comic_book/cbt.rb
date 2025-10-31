require 'rubygems/package'
require_relative 'adapter'
require_relative 'cbt/archiver'
require_relative 'cbt/extractor'

class ComicBook
  class CBT < Adapter
    def archive source_folder, options = {}
      Archiver.new(source_folder).archive options
    end

    def extract destination_folder = nil, options = {}
      Extractor.new(path).extract destination_folder, options
    end

    def pages = collect_pages_from_tar

    private

    def collect_pages_from_tar
      pages = []

      File.open(path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          tar.each do |entry|
            next unless entry.file? && image_file?(entry.full_name)

            pages << create_page_from_entry(entry)
          end
        end
      end

      pages.sort_by &:name
    end

    def create_page_from_entry entry
      basename = File.basename entry.full_name

      ComicBook::Page.new entry.full_name, basename
    end

    def image_file? filename
      extension = File.extname filename.downcase

      ComicBook::IMAGE_EXTENSIONS.include? extension
    end
  end
end
