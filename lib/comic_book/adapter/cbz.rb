require 'zip'
require_relative 'cbz/archiver'
require_relative 'cbz/extractor'

class ComicBook
  module Adapter
    class CBZ < Base
      def archive source_folder, options = {}
        CBZArchiver.new(source_folder).archive options
      end

      def extract destination_folder = nil, options = {}
        CBZExtractor.new(path).extract destination_folder, options
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

        pages.sort_by(&:name)
      end

      def create_page_from_entry entry
        basename = File.basename(entry.name)

        ComicBook::Page.new entry.name, basename
      end

      def image_file? filename
        extension = File.extname(filename.downcase)

        ComicBook::IMAGE_EXTENSIONS.include? extension
      end
    end
  end
end
