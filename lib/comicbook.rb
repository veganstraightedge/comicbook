require_relative 'comic_book/version'
require_relative 'comic_book/page'
require_relative 'comic_book/cb'
require_relative 'comic_book/cb7'
require_relative 'comic_book/cba'
require_relative 'comic_book/cbr'
require_relative 'comic_book/cbt'
require_relative 'comic_book/cbz'
require_relative 'comic_book/pdf'
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

  def self.archive path, options = {}
    new(path).archive options
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

  def archive options = {}
    raise Error, 'Cannot archive a file' unless %i[folder cb].include?(type)

    output_format = options[:to] ? File.extname(options[:to]).downcase : '.cbz'

    case output_format
    when '.cb'  then CB.new(path).archive options
    when '.cb7' then CB7.new(path).archive options
    when '.cbt' then CBT.new(path).archive options
    when '.cbz' then CBZ.new(path).archive options
    else
      raise Error, "Unsupported archive format: #{output_format}"
    end
  end

  def extract options = {}
    raise Error, 'Cannot extract a folder' if type == :folder
    raise Error, '.cb folders are already extracted (they are uncompressed folders)' if type == :cb

    adapter.extract options
  end

  private

  def determine_type path
    if File.directory? path
      File.extname(path).downcase == '.cb' ? :cb : :folder
    elsif File.file? path
      extension = File.extname(path).downcase

      case extension
      when '.cbz' then :cbz
      when '.cb7' then :cb7
      when '.cbt' then :cbt
      when '.cbr' then :cbr
      when '.cba' then :cba
      when '.pdf' then :pdf
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
    when :cb  then CB.new path
    when :cb7 then CB7.new path
    when :cba then CBA.new path
    when :cbr then CBR.new path
    when :cbt then CBT.new path
    when :cbz then CBZ.new path
    when :pdf then PDF.new path
    else
      raise Error, "No adapter available for type: #{type}"
    end
  end
end
