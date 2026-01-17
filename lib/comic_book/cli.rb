require 'optparse'

class ComicBook
  class CLI
    SUPPORTED_FORMATS   = %w[.cb7 .cbr .cbt .cbz].freeze
    UNSUPPORTED_FORMATS = %w[.cba].freeze

    def self.start argv
      new.start Array(argv)
    end

    def start argv
      argv = Array argv

      if argv.empty? || argv.include?('-h') || argv.include?('--help')
        show_help
        return
      end

      case command = argv.shift
      when 'extract' then extract(argv)
      when 'archive' then archive(argv)
      else
        puts "Unknown command: #{command}"
        show_help
        exit 1
      end
    rescue ComicBook::Error, StandardError => e
      puts "Error: #{e.message}"
      exit 1
    end

    private

    def show_help
      puts <<~HELP
        ComicBook CLI

        Usage:
          comicbook extract <file> [options]
          comicbook archive <folder> [options]
          comicbook -h, --help

        Commands:
          extract     Extract comic book archive
          archive     Create comic book archive

        Extract Options:
          --from         Source file path (optional, first arg is default)
          --to           Destination path
          --images-only  Extract only image files (exclude metadata, text, etc.)

        Archive Options:
          --from         Source folder path (optional, first arg is default)
          --to           Destination path

        General Options:
          --help, -h     Show this help
      HELP
    end

    def extract argv
      from_path   = nil
      to_path     = nil
      images_only = false

      parser = OptionParser.new do |opts|
        opts.on('--from PATH',   'Source file path')       { from_path   = it }
        opts.on('--to PATH',     'Destination path')       { to_path     = it }
        opts.on('--images-only', 'Extract only images')    { images_only = true }
      end

      remaining = parser.parse argv
      from_path ||= remaining.first

      validate_extract_args! from_path, to_path

      options = { to: to_path, images_only: images_only }.compact
      options.delete(:images_only) unless images_only
      ComicBook.extract from_path, options

      puts "Extracted #{from_path}#{" to #{to_path}" if to_path}"
    end

    def archive argv
      from_path = nil
      to_path   = nil

      parser = OptionParser.new do |opts|
        opts.on('--from PATH', 'Source folder path') { from_path = it }
        opts.on('--to PATH',   'Destination path')   { to_path   = it }
      end

      remaining = parser.parse argv
      from_path ||= remaining.first

      validate_archive_args! from_path, to_path

      cb = ComicBook.new from_path

      if to_path
        cb.archive to: to_path
      else
        cb.archive
      end

      puts "Archived #{from_path}#{" to #{to_path}" if to_path}"
    end

    def validate_extract_args! from_path, to_path
      # from
      raise ComicBook::Error, 'Source file required' unless from_path
      raise ComicBook::Error, "Source file not found: #{from_path}" unless File.exist?(from_path)
      # to
      raise ComicBook::Error, "Destination already exists: #{to_path}" if to_path && File.exist?(to_path)

      # formats
      ext = File.extname(from_path).downcase
      raise ComicBook::Error, "Unsupported format: #{ext} (not yet implemented)" unless SUPPORTED_FORMATS.include?(ext)

      nil
    end

    def validate_archive_args! from_path, to_path
      # from
      raise ComicBook::Error, 'Source folder required' unless from_path
      raise ComicBook::Error, "Source folder not found: #{from_path}" unless File.exist?(from_path)
      raise ComicBook::Error, "Source must be a directory: #{from_path}" unless File.directory?(from_path)
      # to
      raise ComicBook::Error, "Destination already exists: #{to_path}" if to_path && File.exist?(to_path)

      nil
    end
  end
end
