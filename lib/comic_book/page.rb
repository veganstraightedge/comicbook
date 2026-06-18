class ComicBook
  class Page
    attr_reader :name, :path

    def initialize path, name
      @name = name
      @path = path
    end
  end
end
