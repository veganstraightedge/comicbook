class ComicBook
  class CBT < Adapter
    class Archiver
      def initialize source_folder
        @source_folder = File.expand_path source_folder
      end

      def archive options = {}
        extension = options.fetch :extension, :cbt
        destination = options[:destination] || default_destination(extension)
        delete_original = options.fetch :delete_original, false

        create_tar_file destination
        cleanup_source_folder if delete_original

        destination
      end

      private

      attr_reader :source_folder

      def default_destination extension = :cbt
        basename = File.basename source_folder
        "#{basename}.#{extension}"
      end

      def create_tar_file destination
        File.open(destination, 'wb') do |file|
          Gem::Package::TarWriter.new(file) do |tar|
            add_files_to_tar tar, source_folder
          end
        end
      end

      def add_files_to_tar tar, folder, prefix = ''
        Dir.entries(folder).sort.each do |entry|
          next if ['.', '..'].include?(entry)

          full_path = File.join(folder, entry)
          tar_path = prefix.empty? ? entry : File.join(prefix, entry)

          if File.directory?(full_path)
            add_files_to_tar tar, full_path, tar_path
          elsif image_file?(entry)
            add_file_to_tar tar, full_path, tar_path
          end
        end
      end

      def add_file_to_tar tar, file_path, tar_path
        stat = File.stat(file_path)
        tar.add_file(tar_path, stat.mode) do |io|
          File.open(file_path, 'rb') do |file|
            io.write(file.read)
          end
        end
      end

      def image_file? filename
        extension = File.extname(filename.downcase)
        ComicBook::IMAGE_EXTENSIONS.include? extension
      end

      def cleanup_source_folder
        FileUtils.rm_rf source_folder
      end
    end
  end
end
