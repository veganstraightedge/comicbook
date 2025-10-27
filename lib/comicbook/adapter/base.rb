class ComicBook
  module Adapter
    class Base
      def initialize path
        @path = File.expand_path path
      end

      def archive source_folder, options = {}
        raise NotImplementedError, "#{self.class} must implement #archive"
      end

      def extract destination_folder, options = {}
        raise NotImplementedError, "#{self.class} must implement #extract"
      end

      def pages
        raise NotImplementedError, "#{self.class} must implement #pages"
      end

      private

      attr_reader :path
    end
  end
end
