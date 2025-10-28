require_relative 'comic_book/version'
require_relative 'comic_book/page'
require_relative 'comic_book/cbz'
require_relative 'comic_book/cli_helpers'

class ComicBook
  class Error < StandardError; end

  IMAGE_EXTENSIONS   = %w[.jpg .jpeg .png .gif .bmp .webp].freeze
  IMAGE_GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,webp}'.freeze

  attr_reader :path, :type

  def initialize path
    @path = File.expand_path path.strip
    @type = determine_type path
    validate_path!
  end

  def self.load path
    new path
  end

  def self.extract path, options = {}
    new(path).extract options
  end

  def pages
    case type
    when :folder then folder_pages
    else adapter.pages
    end
  end

  def archive source_folder, options = {}
    raise Error, 'Cannot archive a file' unless type == :folder

    CBZ.new(source_folder).archive source_folder, options
  end

  def extract options = {}
    raise Error, 'Cannot extract a folder' if type == :folder

    adapter.extract nil, options
  end

  private

  def determine_type path
    if File.directory? path
      :folder
    elsif File.file? path
      extension = File.extname(path).downcase

      case extension
      when '.cbz' then :cbz
      when '.cb7' then :cb7
      when '.cbt' then :cbt
      when '.cbr' then :cbr
      when '.cba' then :cba
      else
        raise Error, "Unsupported file type: #{File.extname(path)}"
      end
    else
      raise Error, "Path does not exist: #{path}"
    end
  end

  def validate_path!
    return if File.exist? path

    raise Error, "Path does not exist: #{path}"
  end

  def folder_pages
    pattern     = IMAGE_GLOB_PATTERN
    search_path = File.join @path, '**', pattern
    image_files = Dir.glob search_path, File::FNM_CASEFOLD

    image_files.sort.map do |file|
      basename = File.basename file

      Page.new file, basename
    end
  end

  def adapter
    case type
    # when :cb7 then CB7.new path
    # when :cba then CBA.new path
    # when :cbr then CBR.new path
    # when :cbt then CBT.new path
    when :cbz then CBZ.new path
    else
      raise Error, "No adapter available for type: #{type}"
    end
  end
end
