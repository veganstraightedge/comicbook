require 'rubygems/package'
require 'fileutils'

class ComicBook
  class CBT < Adapter
    class Extractor
      def initialize path
        @path = File.expand_path path
      end

      def extract options = {}
        extension = options.fetch :extension, :cb
        delete_original = options.fetch :delete_original, false
        destination_folder = options[:destination]

        destination = destination_folder || determine_extract_path(extension)
        create_destination_directory destination
        extract_files destination, options
        cleanup_original_archive if delete_original

        destination
      end

      private

      attr_reader :path

      def determine_extract_path extension
        base_name = File.basename path, '.*'
        dir_name = File.dirname path
        archive_name = base_name

        if extension
          extension_str = extension.to_s
          extension_str = extension_str[1..] if extension_str.start_with?('.')
          archive_name << ".#{extension_str}"
        end

        full_path = File.join dir_name, archive_name
        File.expand_path full_path
      end

      def create_destination_directory destination
        FileUtils.mkdir_p destination
      end

      def extract_files destination, options
        File.open(path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            tar.each do |entry|
              next unless entry.file?
              next unless options[:all] || image_file?(entry.full_name)

              extract_entry entry, destination
            end
          end
        end
      end

      def extract_entry entry, destination
        output_path = File.join destination, entry.full_name
        create_parent_directory output_path

        File.binwrite(output_path, entry.read)
      end

      def create_parent_directory file_path
        parent_dir = File.dirname file_path
        FileUtils.mkdir_p parent_dir
      end

      def image_file? filename
        ComicBook::IMAGE_EXTENSIONS.include? File.extname(filename.downcase)
      end

      def cleanup_original_archive
        FileUtils.rm path
      end
    end
  end
end
