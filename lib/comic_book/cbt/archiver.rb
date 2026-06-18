class ComicBook
  class CBT < Adapter
    class Archiver
      def initialize source_folder
        @source_folder = File.expand_path source_folder
      end

      def archive options = {}
        extension       = options.fetch :extension, :cbt
        delete_original = options.fetch :delete_original, false
        contents        = options.fetch :contents, :all

        output_path = options[:to] || determine_output_path(extension)
        create_archive output_path, contents
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

      def create_archive output_path, contents
        File.open(output_path, 'wb') do |file|
          Gem::Package::TarWriter.new(file) do |writer|
            ComicBook::ArchiveContents.files(source_folder, contents).each do |image_file|
              add_file writer, image_file
            end
          end
        end
      end

      def add_file writer, file
        file_path     = Pathname.new file
        source_path   = Pathname.new source_folder
        relative_path = file_path.relative_path_from source_path

        stat = File.stat file
        writer.add_file(relative_path.to_s, stat.mode) do |io|
          File.open(file, 'rb') do |f|
            io.write f.read
          end
        end
      end

      def cleanup_source_folder
        FileUtils.rm_rf source_folder
      end
    end
  end
end
