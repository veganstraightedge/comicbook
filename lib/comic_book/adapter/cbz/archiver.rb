class ComicBook
  module Adapter
    class CBZ < Base
      class Archiver
        def initialize source_folder
          @source_folder = File.expand_path source_folder
        end

        def archive options = {}
          extension       = options.fetch :extension, :cbz
          delete_original = options.fetch :delete_original, false

          output_path = determine_output_path extension
          create_zip_archive output_path
          cleanup_source_folder if delete_original

          output_path
        end

        private

        attr_reader :source_folder

        def determine_output_path extension
          base_name = File.basename source_folder, '.*'
          dir_name  = File.dirname source_folder

          File.expand_path File.join(dir_name, "#{base_name}.#{extension}")
        end

        def create_zip_archive output_path
          Zip::File.open(output_path, create: true) do |zipfile|
            find_image_files.each do |file|
              add_file_to_zip zipfile, file
            end
          end
        end

        def find_image_files
          pattern = File.join(source_folder, '**', ComicBook::IMAGE_GLOB_PATTERN)
          Dir.glob(pattern, File::FNM_CASEFOLD).sort
        end

        def add_file_to_zip zipfile, file
          file_path     = Pathname.new file
          source_path   = Pathname.new source_folder
          relative_path = file_path.relative_path_from source_path

          zipfile.add relative_path.to_s, file
        end

        def cleanup_source_folder
          FileUtils.rm_rf source_folder
        end
      end
    end
  end
end
