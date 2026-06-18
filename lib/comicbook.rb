require_relative 'comic_book/version'
require_relative 'comic_book/page'
require_relative 'comic_book/entry'
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

  Info = ComicInfo::Issue

  IMAGE_EXTENSIONS   = %w[.jpg .jpeg .png .gif .bmp .webp].freeze
  IMAGE_GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,webp}'.freeze

  # Metadata sidecar files (used by the :images_and_info file selection).
  INFO_FILENAMES = %w[ComicInfo.xml MetronInfo.xml].freeze

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

  # Pages are the image files, in path order, wrapped as Page objects.
  # PDF renders synthetic pages and CBA is a stub, so both stay custom.
  def pages
    return adapter.pages if %i[cba pdf].include?(type)

    files(type: :images).map { Page.new it.path, it.name }
  end

  def info = adapter.info

  # The files in this comic, filtered by `type`:
  #   :all (default),
  #   :images,
  #   :images_and_info (images + ComicInfo.xml / MetronInfo.xml)
  def files type: :all
    filter_files adapter.entries, by: type
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
      when '.cb7' then :cb7
      when '.cba' then :cba
      when '.cbr' then :cbr
      when '.cbt' then :cbt
      when '.cbz' then :cbz
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

  def filter_files entries, by:
    case by
    when :all             then entries
    when :images          then entries.select(&:image?)
    when :images_and_info then entries.select { it.image? || it.info? }
    else
      raise Error, "Unknown files type: #{by.inspect} (expected :all, :images, or :images_and_info)"
    end.sort_by(&:path)
  end

  def adapter
    case type
    when :cb7 then CB7.new path
    when :cba then CBA.new path
    when :cbr then CBR.new path
    when :cbt then CBT.new path
    when :cbz then CBZ.new path
    when :pdf then PDF.new path
    when :cb, :folder then CB.new path
    else
      raise Error, "No adapter available for type: #{type}"
    end
  end
end
