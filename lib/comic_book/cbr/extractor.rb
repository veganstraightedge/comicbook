class ComicBook
  class CBR < Adapter
    class Extractor
      def initialize archive_path
        @archive_path = File.expand_path archive_path
      end

      def extract options = {}
        extension          = options.fetch :extension, :cb
        delete_original    = options.fetch :delete_original, false
        destination_folder = options[:to]

        destination = destination_folder || determine_extract_path(extension)
        create_destination_directory destination
        extract_contents destination, options
        cleanup_archive_file if delete_original

        destination
      end

      private

      attr_reader :archive_path

      def create_destination_directory destination
        FileUtils.mkdir_p destination
      end

      def determine_extract_path extension
        base_name    = File.basename archive_path, '.*'
        dir_name     = File.dirname  archive_path
        archive_name = base_name

        archive_name << ".#{extension}" if extension

        full_path = File.join dir_name, archive_name
        File.expand_path full_path
      end

      def image_file? filename
        ComicBook::IMAGE_EXTENSIONS.include? File.extname(filename.downcase)
      end

      def cleanup_archive_file
        File.delete archive_path
      end

      def create_parent_directory file_path
        parent_dir = File.dirname file_path
        FileUtils.mkdir_p parent_dir
      end

      def extract_contents destination, options
        FileUtils.mkdir_p destination
        extract_files destination, options
      end

      def extract_files destination, options
        CLIHelpers.unrar_extract archive_path, destination
        delete_non_images destination if options[:images_only]
      end

      def delete_non_images destination
        archive_entries = CLIHelpers.unrar_list archive_path

        archive_entries.each do |entry|
          next if image_file?(entry)

          file_path = File.join(destination, entry)
          FileUtils.rm_f(file_path)
        end
      end
    end
  end
end
