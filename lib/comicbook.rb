require_relative 'comicbook/version'
require_relative 'comicbook/page'

class ComicBook
  class Error < StandardError; end

  attr_reader :path, :type

  def initialize path
    @path = File.expand_path path.strip
    @type = determine_type @path
    validate_path!
  end

  def self.load path
    new path
  end

  def pages
    case @type
    when :folder then folder_pages
    else archive_pages
    end
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
    return if File.exist? @path

    raise Error, "Path does not exist: #{@path}"
  end

  def folder_pages
    pattern     = '*.{jpg,jpeg,png,gif,bmp,webp}'
    search_path = File.join @path, '**', pattern
    image_files = Dir.glob search_path, File::FNM_CASEFOLD

    image_files.sort.map do |file|
      basename = File.basename file

      Page.new path: file, name: basename
    end
  end

  def archive_pages
    # TODO: Implement archive reading for different formats
    []
  end
end
