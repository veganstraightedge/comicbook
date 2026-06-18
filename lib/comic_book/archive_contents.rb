class ComicBook
  # Selects which files from a source folder get written into an archive.
  #
  # Modes:
  #   :all             - every file in the folder (the default; images, ComicInfo.xml, anything else)
  #   :images_only     - image files only
  #   :images_and_info - image files plus ComicInfo.xml / MetronInfo.xml
  module ArchiveContents
    MODES = %i[all images_only images_and_info].freeze

    module_function

    def files source_folder, mode
      case mode
      when :all             then all_files source_folder
      when :images_only     then image_files source_folder
      when :images_and_info then image_files(source_folder) + info_files(source_folder)
      else
        raise ComicBook::Error, "Unknown archive contents mode: #{mode.inspect} (expected one of #{MODES.join(', ')})"
      end.uniq.sort
    end

    def all_files source_folder
      Dir.glob(File.join(source_folder, '**', '*')).reject { File.directory? it }
    end

    def image_files source_folder
      Dir.glob File.join(source_folder, '**', ComicBook::IMAGE_GLOB_PATTERN), File::FNM_CASEFOLD
    end

    def info_files source_folder
      ComicBook::INFO_FILENAMES.flat_map do |name|
        Dir.glob File.join(source_folder, '**', name), File::FNM_CASEFOLD
      end
    end
  end
end
