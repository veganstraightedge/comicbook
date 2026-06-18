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

      def create_archive output_path, entries
        File.open(output_path, 'wb') do |file|
          Gem::Package::TarWriter.new(file) do |writer|
            entries.each { add_entry writer, it }
          end
        end
      end

      def add_entry writer, entry
        absolute = File.join source_folder, entry.path

        writer.add_file(entry.path, File.stat(absolute).mode) do |io|
          io.write File.binread(absolute)
        end
      end

      def cleanup_source_folder
        FileUtils.rm_rf source_folder
      end
    end
  end
end
