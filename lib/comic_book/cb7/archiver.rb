class ComicBook
  class CB7 < Adapter
    class Archiver
      def initialize source_folder
        @source_folder = File.expand_path source_folder
      end

      def archive options = {}
        extension       = options.fetch :extension, :cb7
        delete_original = options.fetch :delete_original, false
        contents        = options.fetch :contents, :all

        output_path = options[:to] || determine_output_path(extension)
        create_archive output_path, ComicBook.new(source_folder).files(type: contents)
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

      def create_archive output_path, files
        File.open(output_path, 'wb') do |file|
          SevenZipRuby::Writer.open(file) do |writer|
            files.each { add_file writer, it }
          end
        end
      end

      def add_file writer, file
        file_path     = Pathname.new file
        source_path   = Pathname.new source_folder
        relative_path = file_path.relative_path_from source_path

        writer.add_file file, as: relative_path.to_s
      end

      def cleanup_source_folder
        FileUtils.rm_rf source_folder
      end
    end
  end
end
