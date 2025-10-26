class ComicBook
  class Page
    attr_reader :path, :name

    def initialize path:, name:
      @path = path
      @name = name
    end
  end
end
