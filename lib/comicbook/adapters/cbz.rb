require 'zip'
require_relative 'cbz/archiver'
require_relative 'cbz/extractor'

class ComicBook
  module Adapters
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
        ComicBook::Page.new entry.name, File.basename(entry.name)
      end

      def image_file? filename
        %w[.jpg .jpeg .png .gif .bmp .webp].include? File.extname(filename.downcase)
      end
    end
  end
end
