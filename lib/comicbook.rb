require_relative 'comic_book/version'
require_relative 'comic_book/page'
require_relative 'comic_book/page_arranger'
require_relative 'comic_book/entry'
require_relative 'comic_book/cb'
require_relative 'comic_book/cb7'
require_relative 'comic_book/cba'
require_relative 'comic_book/cbr'
require_relative 'comic_book/cbt'
require_relative 'comic_book/cbz'
require_relative 'comic_book/pdf'
require_relative 'comic_book/signature'
require_relative 'comic_book/cli_helpers'

class ComicBook
  class Error < StandardError; end

  Info = ComicInfo::Issue

  IMAGE_EXTENSIONS   = %w[.jpg .jpeg .png .gif .bmp .webp].freeze
  IMAGE_GLOB_PATTERN = '*.{jpg,jpeg,png,gif,bmp,webp}'.freeze

  # Metadata sidecar files (used by the :images_and_info file selection).
  INFO_FILENAMES = %w[ComicInfo.xml MetronInfo.xml].freeze

  # Every kind of comic: a format's file extension, or :folder for a plain folder.
  TYPES = %i[cb cb7 cba cbr cbt cbz folder pdf].freeze

  # The types that can be opened: their pages listed, their metadata read.
  # Everything but :cba, which is recognized but not implemented.
  READABLE_TYPES = %i[cb cb7 cbr cbt cbz folder pdf].freeze

  # The types #archive can produce. RAR and ACE are proprietary, and PDF is only read.
  WRITABLE_TYPES = %i[cb cb7 cbt cbz].freeze

  # How #arrange_pages names page files unless told otherwise: page_001, page_002, ...
  DEFAULT_PAGE_FILENAME_TEMPLATE = 'page_{page:3}'.freeze

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

  def info = adapter.info

  # Make this folder's page images exactly `sources`, in that order.
  #
  # Use it to reorder, delete, and add pages of an extracted comic before archiving it again:
  #
  #   comic = ComicBook.load 'Issue1.cb'
  #   # Move the last of three pages to the front, drop the second, and add a new one.
  #   comic.arrange_pages ['page3.jpg', 'page1.jpg', '/Users/me/Desktop/extra.png']
  #
  # Each source is an image file: a path relative to the folder for a page already in it,
  # or an absolute path for a file anywhere (it is copied in). Afterwards:
  #
  # - The pages are named from `template` in the given order, keeping their extensions:
  #   page_001, page_002, ... unless you pass another. ComicInfo::Issue#page_filename fills
  #   the template in, so it can use {page} and the comic's details, such as
  #   '{series}_{number:3}_{page:4}', and the names always sort in page order.
  # - They are in the folder their pages were in before (the shared parent, if there were several).
  # - Page images left out of `sources` are deleted. Files that are not images are left alone.
  # - If the folder has a ComicInfo.xml, its <Page> entries and PageCount are updated to follow
  #   the pages (see ComicInfo::Issue#rearranging_pages).
  #
  # Only a folder or .cb can be arranged; extract an archive first.
  # Returns the comic's pages afterwards. Raises Error, changing nothing, for a source that is
  # missing or is not an image.
  def arrange_pages sources, template: DEFAULT_PAGE_FILENAME_TEMPLATE
    raise Error, "Cannot arrange the pages of a #{type} file; extract it first" unless %i[folder cb].include?(type)

    PageArranger.new(path).arrange sources, template:
  end

  # The files in this comicbook, filtered by type:
  #   :all (default),
  #   :images,
  #   :images_and_info (images + ComicInfo.xml / MetronInfo.xml)
  def files type: :all
    filter_files adapter.entries, by: type
  end

  # Pages are the image files, in path order, wrapped as Page objects.
  # PDF renders synthetic pages and CBA is a stub, so both stay custom.
  def pages
    return adapter.pages if %i[cba pdf].include?(type)

    files(type: :images).map { Page.new it.path, it.name }
  end

  private

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

  def determine_type path
    if File.directory? path
      File.extname(path).downcase == '.cb' ? :cb : :folder
    elsif File.file? path
      # The name says whether this is a comic at all.
      # What kind it is comes from its contents, which are right more often than its name.
      named = type_named File.extname(path)

      Signature.new(path).type || named
    else
      raise Error, "Path does not exist: #{path}"
    end
  end

  def type_named extension
    case extension.downcase
    when '.cb7' then :cb7
    when '.cba' then :cba
    when '.cbr' then :cbr
    when '.cbt' then :cbt
    when '.cbz' then :cbz
    when '.pdf' then :pdf
    else
      raise Error, "Unsupported file type: #{extension}"
    end
  end

  def filter_files entries, by:
    case by
    when :all             then entries
    when :images          then images
    when :images_and_info then images_and_info
    else
      raise Error, "Unknown files type: #{by.inspect} (expected :all, :images, or :images_and_info)"
    end.sort_by(&:path)
  end

  def images          = adapter.images
  def images_and_info = adapter.images_and_info

  def validate_path!
    return if File.exist? path

    raise Error, "Path does not exist: #{path}"
  end
end
