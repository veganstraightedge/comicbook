class ComicBook
  class PDF < Adapter
    class Extractor
      DEFAULT_DPI = 300

      def initialize pdf_path
        @pdf_path = File.expand_path pdf_path
      end

      def extract options = {}
        extension       = options.fetch :extension, :cb
        delete_original = options.fetch :delete_original, false
        @dpi            = options.fetch :dpi, DEFAULT_DPI

        destination = options[:to] || determine_extract_path(extension)
        create_destination_directory destination
        render_pages destination
        cleanup_pdf_file if delete_original

        destination
      end

      private

      attr_reader :pdf_path, :dpi

      def determine_extract_path extension
        base_name = File.basename pdf_path, '.*'
        dir_name  = File.dirname  pdf_path
        pdf_name  = base_name

        pdf_name << ".#{extension}" if extension

        full_path = File.join dir_name, pdf_name
        File.expand_path full_path
      end

      def create_destination_directory destination
        FileUtils.mkdir_p destination
      end

      def page_count
        require 'vips'
        image = Vips::Image.new_from_file pdf_path
        image.get 'n-pages'
      rescue StandardError => e
        raise unless e.class.name == 'Vips::Error' # rubocop:disable Style/ClassEqualityComparison

        0
      end

      def render_pages destination
        count = page_count
        return if count.zero?

        count.times do |page_number|
          render_page destination, page_number
        end
      end

      def render_page destination, page_number
        require 'vips'
        image     = Vips::Image.new_from_file pdf_path, page: page_number, dpi: dpi
        file_name = format('page_%03d.jpg', page_number + 1)
        file_path = File.join destination, file_name

        image.jpegsave file_path
      end

      def cleanup_pdf_file
        File.delete pdf_path
      end
    end
  end
end
