require 'optparse'
require 'json'
require 'yaml'

class ComicBook
  class CLI
    EXTRACT_FORMATS     = %w[.cb .cb7 .cbr .cbt .cbz .pdf].freeze
    ARCHIVE_FORMATS     = %w[.cb .cb7 .cbt .cbz].freeze
    INFO_FORMATS        = %w[.cb .cb7 .cbr .cbt .cbz].freeze
    UNSUPPORTED_FORMATS = %w[.cba].freeze

    # Fields that duplicate others in a less useful form
    REDUNDANT_FIELDS = %i[
      genre genres_raw_data
      characters_raw_data
      teams_raw_data
      locations_raw_data
      story_arc story_arcs_raw_data
      story_arc_number story_arc_numbers_raw_data
      web_urls
    ].freeze

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
      when 'info'    then info(argv)
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
        ComicBook CLI for .cb, .cb7, .cbt, .cbz, .cbr, .pdf files

        Usage:
          comicbook extract <file> [options]
          comicbook archive <folder> [options]
          comicbook info <file> [options]
          comicbook -h, --help

        Commands:
          extract  Extract comic book archive (.cb7, .cbr, .cbt, .cbz, .cb, .pdf)
          archive  Create comic book archive (.cb7, .cbt, .cbz, .cb)
          info     Show ComicInfo.xml metadata (.cb7, .cbr, .cbt, .cbz, .cb)

        Extract Options:
          --from            Source file path (optional, first arg is default)
          --to              Destination path
          --images-only     Extract only image files (exclude metadata, text, etc.)
          --delete-original Delete source archive after extraction

        Archive Options:
          --from            Source folder path (optional, first arg is default)
          --to              Destination path (extension determines format, default .cbz)
          --delete-original Delete source folder after archiving

        Info Options:
          --from            Source file path (optional, first arg is default)
          --format FORMAT   Output format: verbose (default), terse, json, yaml
          --only FIELDS     Only show these fields (comma-separated)
          --except FIELDS   Show all fields except these (comma-separated)

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

    def info argv
      from_path     = nil
      output_format = 'verbose'
      only_fields   = nil
      except_fields = nil

      parser = OptionParser.new do |opts|
        opts.on('--from PATH',     'Source file path')     { from_path     = it }
        opts.on('--format FORMAT', 'Output format')        { output_format = it }
        opts.on('--only FIELDS',   'Only these fields')    { only_fields   = it.split(',').map(&:strip) }
        opts.on('--except FIELDS', 'Exclude these fields') { except_fields = it.split(',').map(&:strip) }
      end

      remaining = parser.parse argv
      from_path ||= remaining.first

      validate_info_args! from_path, output_format

      comic_info = ComicBook.new(from_path).info

      raise ComicBook::Error, "No ComicInfo.xml found in #{from_path}" unless comic_info

      data = comic_info.to_h
      data = filter_fields data, only_fields, except_fields

      puts format_info(data, output_format)
    end

    def validate_info_args! from_path, output_format
      raise ComicBook::Error, 'Source file required' unless from_path
      raise ComicBook::Error, "Source file not found: #{from_path}" unless File.exist?(from_path)

      valid_formats = %w[verbose terse json yaml]
      return if valid_formats.include? output_format

      raise ComicBook::Error, "Invalid format: #{output_format} (valid: #{valid_formats.join(', ')})"
    end

    def filter_fields data, only_fields, except_fields
      if only_fields
        data.select { |key, _| only_fields.include? key.to_s }
      elsif except_fields
        data.reject { |key, _| except_fields.include? key.to_s }
      else
        data
      end
    end

    def format_info data, output_format
      data = data.compact

      case output_format
      when 'json'    then format_json(data)
      when 'yaml'    then format_yaml(data)
      when 'terse'   then format_terse(data)
      when 'verbose' then format_verbose(data)
      end
    end

    def format_json data
      JSON.generate(data.transform_keys(&:to_s))
    end

    def format_yaml data
      data.transform_keys(&:to_s).to_yaml.delete_prefix("---\n")
    end

    def clean_for_display data
      data.except(*REDUNDANT_FIELDS)
    end

    def format_terse data
      clean_for_display(data).map { |key, value| "#{key}=#{value}" }.join(' | ')
    end

    def format_verbose data
      data = clean_for_display(data)
      max_key_length = data.keys.map { it.to_s.length }.max || 0

      data.map { |key, value| "#{key.to_s.ljust max_key_length}  #{value}" }.join("\n")
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
