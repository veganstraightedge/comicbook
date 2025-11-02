# NOTE: don't use ComicBook::Adapter.new directly
#       Inherit from it when making an adapter to formats:
#       .cb7 .cba .cbr .cbt .cbz
class ComicBook
  class Adapter
    def initialize path
      @path = File.expand_path path
    end

    def archive options = {}
      raise NotImplementedError, "#{self.class} must implement #archive"
    end

    def extract options = {}
      raise NotImplementedError, "#{self.class} must implement #extract"
    end

    def pages
      raise NotImplementedError, "#{self.class} must implement #pages"
    end

    private

    attr_reader :path
  end
end
