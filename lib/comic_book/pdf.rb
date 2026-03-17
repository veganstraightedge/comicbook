require 'vips'
require_relative 'adapter'
require_relative 'pdf/extractor'

class ComicBook
  class PDF < Adapter
    def archive _options = {}
      raise Error, 'PDF archiving not supported (use extract to convert PDF pages to images)'
    end

    def extract options = {}
      Extractor.new(path).extract options
    end

    def pages
      image = Vips::Image.new_from_file path
      count = image.get 'n-pages'

      (1..count).map do |page_number|
        name = format('page_%03d.jpg', page_number)

        ComicBook::Page.new name, name
      end
    rescue Vips::Error
      []
    end
  end
end
