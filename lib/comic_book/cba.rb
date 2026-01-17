require_relative 'adapter'

class ComicBook
  class CBA < Adapter
    def archive _options = {}
      raise Error, 'CBA archiving not supported (ACE is proprietary)'
    end

    def extract _options = {}
      raise Error, 'CBA extraction not yet implemented'
    end

    def pages
      raise Error, 'CBA page listing not yet implemented'
    end
  end
end
