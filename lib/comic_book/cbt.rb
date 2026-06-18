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

    def entries
      names = []

      File.open(path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |reader|
          reader.each do |entry|
            names << entry.full_name if entry.file?
          end
        end
      end

      names.map { ComicBook::Entry.new it }
    end
  end
end
