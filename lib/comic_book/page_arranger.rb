require 'comicinfo'
require 'fileutils'
require 'tmpdir'

class ComicBook
  # Makes a folder's page images exactly the given files, in the given order.
  #
  # See ComicBook#arrange_pages, which this does the work for.
  class PageArranger
    # An issue with no details, for filling in a template when the folder has no ComicInfo.xml.
    BLANK_ISSUE_XML = '<ComicInfo/>'.freeze

    def initialize folder
      @folder = File.realpath folder
    end

    def arrange sources, template:
      previous_pages = comic.pages.map(&:path)
      resolved       = sources.map { resolve it, previous_pages }
      files          = resolved.map { it[:path] }
      order          = resolved.map { it[:previous_index] }

      Dir.mktmpdir 'comicbook-arrange' do |staging|
        staged = stage files, staging, template
        replace_pages previous_pages, staged
      end

      update_info order
      comic.pages
    end

    private

    attr_reader :folder

    # Delete the pages the folder had, and move the staged ones into where they were.
    def replace_pages previous_pages, staged
      previous_pages.each { FileUtils.rm File.join(folder, it) }

      pages_directory = File.join folder, shared_directory(previous_pages)
      FileUtils.mkdir_p pages_directory
      staged.each { FileUtils.mv it, File.join(pages_directory, File.basename(it)) }
    end

    def comic = ComicBook.new(folder)

    def info_path = File.join(folder, 'ComicInfo.xml')

    # Where a source is on disk, and which page it was before (nil for a file new to the comic).
    def resolve source, previous_pages
      path = source.start_with?('/') ? source : File.join(folder, source)

      raise Error, "Path does not exist: #{path}" unless File.exist? path
      raise Error, "Unsupported file type: #{File.extname(path)}" unless Entry.new(path).image?

      path           = File.realpath path
      folder_prefix  = "#{folder}/"
      previous_index = previous_pages.index(path.delete_prefix(folder_prefix)) if path.start_with? folder_prefix

      { path:, previous_index: }
    end

    # Copy the files into the staging folder under their new page names, in order.
    def stage files, staging, template
      issue = File.exist?(info_path) ? ComicInfo.load(info_path) : ComicInfo.load(BLANK_ISSUE_XML)

      files.each_with_index.map do |file, index|
        name        = issue.page_filename template:, page: index + 1, of: files.length
        destination = File.join staging, "#{name}#{File.extname(file)}"

        FileUtils.cp file, destination
        destination
      end
    end

    # The deepest directory that contains every one of the paths, relative like them ("" for the top).
    def shared_directory paths
      directories = paths.map { it.split('/')[0...-1] }
      shared      = directories.first || []

      directories.drop(1).each do |directory|
        shared = shared.zip(directory).take_while { |ours, theirs| ours == theirs }.map(&:first)
      end

      shared.join '/'
    end

    # Bring the folder's ComicInfo.xml (if any) in step with the rearranged pages.
    def update_info order
      return unless File.exist? info_path

      ComicInfo.load(info_path).rearranging_pages(order).save info_path
    end
  end
end
