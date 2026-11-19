class ComicBook
  # A single member of a comic book: an image, an info file
  # (ComicInfo.xml / MetronInfo.xml), or anything else.
  #
  # `path` locates it within the comic:
  #    a relative path in a folder,
  #    or an entry name in an archive
  # `name` is its basename.
  class Entry
    attr_reader :path, :name

    def initialize path
      @path = path
      @name = File.basename path
    end

    def image? = ComicBook::IMAGE_EXTENSIONS.include?(File.extname(name).downcase)
    def info?  = ComicBook::INFO_FILENAMES.include?(name)

    # True if macOS added this to an archive, so it is not part of the comic:
    #    an AppleDouble member (`._page1.jpg`, which tar writes beside a file
    #    that has extended attributes),
    #    or anything in a `__MACOSX` folder (where Finder's Compress puts the same data).
    # Such members are never listed, counted as pages, or extracted.
    def macos_metadata?
      path.split('/').any? { it == '__MACOSX' || it.start_with?('._') }
    end
  end
end
