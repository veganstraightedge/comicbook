require_relative 'comicbook/version'

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

  private

  def determine_type path
    if File.directory? path
      :folder
    elsif File.file? path
      case File.extname(path).downcase
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
end
