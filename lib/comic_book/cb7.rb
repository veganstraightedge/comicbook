require 'seven_zip_ruby'
require 'comicinfo'
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

    def entries
      names = []

      File.open(path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |reader|
          reader.entries.each do |entry|
            names << entry.path if entry.file?
          end
        end
      end

      names.map { ComicBook::Entry.new it }
    end

    def info
      xml = nil

      File.open(path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |reader|
          entry = reader.entries.find { it.path == 'ComicInfo.xml' }
          xml   = reader.extract_data(entry.index) if entry
        end
      end

      return nil unless xml

      ComicInfo.load xml
    end
  end
end
