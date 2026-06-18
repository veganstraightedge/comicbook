require 'zip'
require 'comicinfo'
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

    def info
      xml = nil

      Zip::File.open(path) do |zipfile|
        entry = zipfile.find_entry('ComicInfo.xml')
        xml   = entry&.get_input_stream&.read
      end

      return nil unless xml

      ComicInfo.load xml
    end

    def entries
      names = []

      Zip::File.open(path) do |zipfile|
        zipfile.each { |entry| names << entry.name if entry.file? }
      end

      names.map { ComicBook::Entry.new it }
    end
  end
end
