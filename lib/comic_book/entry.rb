class ComicBook
  # A single member of a comic book: an image, an info file (ComicInfo.xml / MetronInfo.xml),
  # or anything else.
  #
  # `path` locates it within the comic — a relative path in a folder, an entry name in an
  # archive — and `name` is its basename.
  class Entry
    attr_reader :path, :name

    def initialize path
      @path = path
      @name = File.basename path
    end

    def image? = ComicBook::IMAGE_EXTENSIONS.include?(File.extname(name).downcase)
    def info?  = ComicBook::INFO_FILENAMES.include?(name)
  end
end
