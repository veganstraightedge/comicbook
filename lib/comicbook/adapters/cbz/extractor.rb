require 'zip'

class ComicBook
  module Adapters
    class CBZExtractor
      def initialize archive_path
        @archive_path = File.expand_path(archive_path)
      end

      def extract destination_folder = nil, options = {}
        extension       = options.fetch :extension, :cb
        delete_original = options.fetch :delete_original, false

        destination = destination_folder || determine_extract_path(extension)
        extract_zip_contents destination
        cleanup_archive_file if delete_original

        destination
      end

      private

      attr_reader :archive_path

      def determine_extract_path extension
        base_name = File.basename archive_path, '.*'
        dir_name  = File.dirname archive_path

        if extension
          file_name = "#{base_name}.#{extension}"
          archive_name = file_name
        else
          archive_name = base_name
        end

        full_path = File.join dir_name, archive_name
        File.expand_path full_path
      end

      def extract_zip_contents destination
        FileUtils.mkdir_p destination

        Dir.chdir(File.dirname(destination)) do
          destination_basename = File.basename destination
          extract_files_from_zip destination_basename
        end
      end

      def extract_files_from_zip destination_basename
        Zip::File.open(archive_path) do |zipfile|
          zipfile.each do |entry|
            next unless image_file?(entry.name)

            extract_single_file entry, destination_basename
          end
        end
      end

      def extract_single_file entry, destination_basename
        file_path = File.join(destination_basename, entry.name)
        FileUtils.mkdir_p File.dirname(file_path)

        entry.extract(file_path) { true }
      end

      def cleanup_archive_file
        File.delete archive_path
      end

      def image_file? filename
        %w[.jpg .jpeg .png .gif .bmp .webp].include? File.extname(filename.downcase)
      end
    end
  end
end
