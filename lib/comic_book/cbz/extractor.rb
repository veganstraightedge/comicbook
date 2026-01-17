class ComicBook
  class CBZ < Adapter
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

        Dir.chdir(File.dirname(destination)) do
          destination_basename = File.basename destination
          extract_files destination_basename, options
        end
      end

      def extract_files destination_basename, options
        Zip::File.open(archive_path) do |zipfile|
          zipfile.each do |entry|
            next unless options[:all] || image_file?(entry.name)

            extract_single_file entry, destination_basename
          end
        end
      end

      def extract_single_file entry, destination_basename
        file_path = File.join destination_basename, entry.name
        create_parent_directory file_path

        entry.extract(file_path) { true }
      end
    end
  end
end
