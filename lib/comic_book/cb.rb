require 'comicinfo'
require_relative 'adapter'
require_relative 'cb/archiver'
require_relative 'cb/extractor'

class ComicBook
  class CB < Adapter
    def archive options = {}
      Archiver.new(path).archive options
    end

    def extract _options = {}
      Extractor.new(path).extract
    end

    # Every file in the folder, as Entries with folder-relative paths
    def entries
      Dir.glob(File.join(path, '**', '*')).reject { File.directory? it }.map do |file|
        relative = Pathname.new(file).relative_path_from(Pathname.new(path)).to_s
        ComicBook::Entry.new relative
      end
    end

    def info
      xml_path = File.join path, 'ComicInfo.xml'
      return nil unless File.exist? xml_path

      ComicInfo.load xml_path
    end
  end
end
