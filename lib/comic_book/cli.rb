require 'optparse'

class ComicBook
  class CLI
    EXTRACT_FORMATS     = %w[.cb .cb7 .cbr .cbt .cbz].freeze
    ARCHIVE_FORMATS     = %w[.cb .cb7 .cbt .cbz].freeze
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
        ComicBook CLI for .cb, .cb7, .cbt, .cbz, .cbr files

        Usage:
          comicbook extract <file> [options]
          comicbook archive <folder> [options]
          comicbook -h, --help

        Commands:
          extract  Extract comic book archive (.cb7, .cbr, .cbt, .cbz, .cb)
          archive  Create comic book archive (.cb7, .cbt, .cbz, .cb)

        Extract Options:
          --from            Source file path (optional, first arg is default)
          --to              Destination path
          --images-only     Extract only image files (exclude metadata, text, etc.)
          --delete-original Delete source archive after extraction

        Archive Options:
          --from            Source folder path (optional, first arg is default)
          --to              Destination path (extension determines format, default .cbz)
          --delete-original Delete source folder after archiving

        General Options:
          --help, -h     Show this help
      HELP
    end

    def extract argv
      from_path       = nil
      to_path         = nil
      images_only     = false
      delete_original = false

      parser = OptionParser.new do |opts|
        opts.on('--from PATH',       'Source file path')            { from_path       = it }
        opts.on('--to PATH',         'Destination path')            { to_path         = it }
        opts.on('--images-only',     'Extract only images')         { images_only     = true }
        opts.on('--delete-original', 'Delete source after extract') { delete_original = true }
      end

      remaining = parser.parse argv
      from_path ||= remaining.first

      validate_extract_args! from_path, to_path

      options = { to: to_path, images_only: images_only, delete_original: delete_original }.compact

      options.delete(:images_only)     unless images_only
      options.delete(:delete_original) unless delete_original

      ComicBook.extract from_path, options

      puts "Extracted #{from_path}#{" to #{to_path}" if to_path}"
    end

    def archive argv
      from_path       = nil
      to_path         = nil
      delete_original = false

      parser = OptionParser.new do |opts|
        opts.on('--from PATH',       'Source folder path')           { from_path       = it }
        opts.on('--to PATH',         'Destination path')             { to_path         = it }
        opts.on('--delete-original', 'Delete source after archive')  { delete_original = true }
      end

      remaining = parser.parse argv
      from_path ||= remaining.first

      validate_archive_args! from_path, to_path

      cb = ComicBook.new from_path

      options = {}
      options[:to]              = to_path if to_path
      options[:delete_original] = true    if delete_original

      cb.archive options

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

      if ext == '.cb' && File.directory?(from_path)
        raise ComicBook::Error, '.cb folders are already extracted (they are uncompressed folders)'
      end

      raise ComicBook::Error, "Unsupported format: #{ext} (not yet implemented)" unless EXTRACT_FORMATS.include?(ext)

      nil
    end

    def validate_archive_args! from_path, to_path
      # from
      raise ComicBook::Error, 'Source folder required' unless from_path
      raise ComicBook::Error, "Source folder not found: #{from_path}" unless File.exist?(from_path)
      raise ComicBook::Error, "Source must be a directory: #{from_path}" unless File.directory?(from_path)
      # to
      raise ComicBook::Error, "Destination already exists: #{to_path}" if to_path && File.exist?(to_path)

      # output format
      if to_path
        ext = File.extname(to_path).downcase

        if ext == '.cbr'
          raise ComicBook::Error, 'Cannot archive to CBR format (RAR is proprietary)'
        elsif ext == '.cba'
          raise ComicBook::Error, 'Cannot archive to CBA format (ACE is not supported)'
        elsif !ARCHIVE_FORMATS.include?(ext)
          raise ComicBook::Error, "Unsupported archive format: #{ext}"
        end
      end

      nil
    end
  end
end
