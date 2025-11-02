class ComicBook
  class CB7 < Adapter
    class Extractor
      def initialize archive_path
        @archive_path = File.expand_path(archive_path)
      end

      def extract options = {}
        extension = options.fetch :extension, :cb
        delete_original = options.fetch :delete_original, false
        destination_folder = options[:destination]

        destination = destination_folder || determine_extract_path(extension)
        extract_7z_contents destination
        cleanup_archive_file if delete_original

        destination
      end

      private

      attr_reader :archive_path

      def determine_extract_path extension
        base_name    = File.basename archive_path, '.*'
        dir_name     = File.dirname archive_path
        archive_name = base_name

        archive_name << ".#{extension}" if extension

        full_path = File.join dir_name, archive_name
        File.expand_path full_path
      end

      def extract_7z_contents destination
        FileUtils.mkdir_p destination

        File.open(archive_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            szr.entries.each do |entry|
              next unless entry.file? && image_file?(entry.path)

              extract_single_file entry, destination, szr
            end
          end
        end
      end

      def extract_single_file entry, destination, szr
        file_path = File.join(destination, entry.path)
        FileUtils.mkdir_p File.dirname(file_path)

        File.binwrite(file_path, szr.extract_data(entry))
      end

      def cleanup_archive_file
        File.delete archive_path
      end

      def image_file? filename
        ComicBook::IMAGE_EXTENSIONS.include? File.extname(filename.downcase)
      end
    end
  end
end
