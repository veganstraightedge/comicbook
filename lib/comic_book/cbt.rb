require 'rubygems/package'
require 'comicinfo'
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

    def info
      xml = nil

      File.open(path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |reader|
          reader.each do |entry|
            next unless entry.full_name == 'ComicInfo.xml'

            xml = entry.read
            break
          end
        end
      end

      return nil unless xml

      ComicInfo.load xml
    end

    def pages
      entries = []

      File.open(path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |reader|
          reader.each do |entry|
            entries << entry.full_name if entry.file?
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
