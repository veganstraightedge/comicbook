require_relative 'adapter'
require_relative 'pdf/extractor'

class ComicBook
  class PDF < Adapter
    def archive _options = {}
      raise Error, 'PDF archiving not supported (use extract to convert PDF pages to images)'
    end

    def extract options = {}
      require_vips!
      Extractor.new(path).extract options
    end

    def pages
      require_vips!
      image = Vips::Image.new_from_file path
      count = image.get 'n-pages'

      (1..count).map do |page_number|
        name = format('page_%03d.jpg', page_number)

        ComicBook::Page.new name, name
      end
    rescue Vips::Error
      []
    end

    private

    def require_vips!
      require 'vips'
    rescue LoadError
      raise ComicBook::Error, 'PDF support requires libvips. Install with: brew install vips (macOS) or apt install libvips-dev (Linux)'
    end
  end
end
