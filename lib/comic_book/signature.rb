class ComicBook
  # Tells what kind of file a comic is from the bytes it starts with.
  #
  # Comic files are often mislabelled (a RAR named `.cbz`),
  # so what the file is matters more than what it is called.
  class Signature
    # How many leading bytes are enough to recognize any format
    # (TAR's marker ends at byte 262).
    LENGTH = 262

    ZIP_FILE_HEADER = "PK\x03\x04".b.freeze
    ZIP_END_RECORD  = "PK\x05\x06".b.freeze # an empty archive starts with this
    RAR             = "Rar!\x1A\x07".b.freeze # versions 4 and 5
    SEVEN_ZIP       = "7z\xBC\xAF\x27\x1C".b.freeze
    PDF             = '%PDF-'.b.freeze
    ACE             = '**ACE**'.b.freeze
    ACE_OFFSET      = 7
    TAR             = 'ustar'.b.freeze
    TAR_OFFSET      = 257

    def initialize path
      @path = path
    end

    # The type the file's contents say it is (:cbz, :cbr, :cb7, :pdf, :cba, :cbt).
    #
    # Nil when the file can't be read or starts like none of the formats;
    # an old TAR with no `ustar` marker is one such file.
    def type
      return :cbz if zip?
      return :cbr if starts_with? RAR
      return :cb7 if starts_with? SEVEN_ZIP
      return :pdf if starts_with? PDF
      return :cba if marker? ACE, at: ACE_OFFSET
      return :cbt if marker? TAR, at: TAR_OFFSET

      nil
    end

    private

    attr_reader :path

    def zip? = starts_with?(ZIP_FILE_HEADER) || starts_with?(ZIP_END_RECORD)

    def starts_with? marker
      marker? marker, at: 0
    end

    def marker? marker, at:
      bytes.byteslice(at, marker.bytesize) == marker
    end

    def bytes
      @bytes ||= File.binread(path, LENGTH) || ''.b
    rescue SystemCallError
      @bytes = ''.b
    end
  end
end
