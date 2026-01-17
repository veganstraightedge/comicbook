class ComicBook
  class CB < Adapter
    class Archiver
      def initialize source_path
        @source_path = File.expand_path source_path
      end

      def archive options = {}
        output_path = options[:to] || determine_output_path

        validate_destination! output_path

        if File.directory? source_path
          archive_folder output_path
        else
          archive_file output_path
        end

        output_path
      end

      private

      attr_reader :source_path

      def determine_output_path
        base_name = File.basename source_path, '.*'
        dir_name  = File.dirname  source_path

        File.expand_path File.join(dir_name, "#{base_name}.cb")
      end

      def validate_destination! output_path
        return unless File.exist? output_path

        raise ComicBook::Error, "Destination already exists: #{output_path}"
      end

      def archive_folder output_path
        FileUtils.mv source_path, output_path
      end

      def archive_file output_path
        FileUtils.mkdir_p output_path
        FileUtils.mv source_path, output_path
      end
    end
  end
end
