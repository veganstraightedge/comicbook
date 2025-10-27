require 'zip'

class ComicBook
  module Adapters
    class Cbz < Base
      def archive source_folder, options = {}
        source_folder = File.expand_path(source_folder)
        extension = options.fetch(:extension, :cbz)
        delete_original = options.fetch(:delete_original, false)

        output_path = determine_output_path(source_folder, extension)

        Zip::File.open(output_path, create: true) do |zipfile|
          image_files = Dir.glob(File.join(source_folder, '**', '*.{jpg,jpeg,png,gif,bmp,webp}'), File::FNM_CASEFOLD)
          image_files.sort.each do |file|
            relative_path = Pathname.new(file).relative_path_from(Pathname.new(source_folder))
            zipfile.add(relative_path.to_s, file)
          end
        end

        FileUtils.rm_rf(source_folder) if delete_original

        output_path
      end

      def extract destination_folder = nil, options = {}
        extension = options.fetch(:extension, :cb)
        delete_original = options.fetch(:delete_original, false)

        destination = destination_folder || determine_extract_path(extension)
        FileUtils.mkdir_p(destination)

        Dir.chdir(File.dirname(destination)) do
          destination_basename = File.basename(destination)

          Zip::File.open(path) do |zipfile|
            zipfile.each do |entry|
              next unless image_file?(entry.name)

              file_path = File.join(destination_basename, entry.name)
              FileUtils.mkdir_p(File.dirname(file_path))
              entry.extract(file_path) { true }
            end
          end
        end

        File.delete(path) if delete_original

        destination
      end

      def pages
        pages = []
        Zip::File.open(path) do |zipfile|
          zipfile.each do |entry|
            next unless image_file?(entry.name)

            pages << ComicBook::Page.new(entry.name, File.basename(entry.name))
          end
        end
        pages.sort_by(&:name)
      end

      private

      def determine_output_path source_folder, extension
        source_folder = File.expand_path(source_folder)
        base_name = File.basename(source_folder, '.*')
        dir_name = File.dirname(source_folder)
        File.expand_path(File.join(dir_name, "#{base_name}.#{extension}"))
      end

      def determine_extract_path extension
        absolute_path = File.expand_path(path)
        base_name = File.basename(absolute_path, '.*')
        dir_name = File.dirname(absolute_path)
        if extension
          File.expand_path(File.join(dir_name, "#{base_name}.#{extension}"))
        else
          File.expand_path(File.join(dir_name, base_name))
        end
      end

      def image_file? filename
        %w[.jpg .jpeg .png .gif .bmp .webp].include?(File.extname(filename.downcase))
      end
    end
  end
end
