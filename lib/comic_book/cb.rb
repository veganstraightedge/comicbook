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

    def pages
      pattern     = ComicBook::IMAGE_GLOB_PATTERN
      search_path = File.join path, '**', pattern
      image_files = Dir.glob search_path, File::FNM_CASEFOLD

      image_files.sort.map do |file|
        relative_path = Pathname.new(file).relative_path_from(Pathname.new(path)).to_s
        basename      = File.basename file

        ComicBook::Page.new relative_path, basename
      end
    end
  end
end
