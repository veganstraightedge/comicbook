class ComicBook
  class CBT < Adapter
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
        File.open(archive_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            extract_files destination, options, tar
          end
        end
      end

      def extract_files destination, options, tar
        tar.each do |entry|
          next unless entry.file?
          next if options[:images_only] && !image_file?(entry.full_name)

          extract_single_file entry, destination
        end
      end

      def extract_single_file entry, destination
        file_path = File.join destination, entry.full_name
        create_parent_directory file_path

        File.binwrite file_path, entry.read
      end
    end
  end
end
