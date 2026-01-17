class ComicBook
  class CB < Adapter
    class Extractor
      def initialize archive_path
        @archive_path = File.expand_path archive_path
      end

      def extract
        raise ComicBook::Error, '.cb folders are already extracted (they are uncompressed folders)'
      end

      private

      attr_reader :archive_path
    end
  end
end
