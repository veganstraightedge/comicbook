# NOTE: don't use ComicBook::Adapter.new directly
#       Inherit from it when making an adapter to formats:
#       .cb .cb7 .cba .cbr .cbt .cbz .pdf
class ComicBook
  class Adapter
    def initialize path
      @path = File.expand_path path
    end

    def archive options = {}
      raise NotImplementedError, "#{self.class} must implement #archive"
    end

    def entries
      raise NotImplementedError, "#{self.class} must implement #entries"
    end

    def extract options = {}
      raise NotImplementedError, "#{self.class} must implement #extract"
    end

    def info
      raise NotImplementedError, "#{self.class} must implement #info"
    end

    def images = entries.select(&:image?)
    def images_and_info = entries.select { it.image? || it.info? }

    def pages
      raise NotImplementedError, "#{self.class} must implement #pages"
    end

    private

    attr_reader :path
  end
end
