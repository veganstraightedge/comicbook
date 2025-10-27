require 'spec_helper'
require 'tmpdir'

RSpec.describe ComicBook::Adapters::CBZExtractor do
  subject(:extractor) { described_class.new(test_cbz) }

  let(:temp_dir)      { Dir.mktmpdir }
  let(:source_folder) { File.join temp_dir, 'source' }
  let(:test_cbz)      { File.join temp_dir, 'test.cbz' }

  before do
    Dir.mkdir source_folder

    File.write File.join(source_folder, 'page1.jpg'), 'image1 content'
    File.write File.join(source_folder, 'page2.png'), 'image2 content'
    File.write File.join(source_folder, 'page3.gif'), 'image3 content'

    # Create a real CBZ file using CBZArchiver
    archiver    = ComicBook::Adapters::CBZArchiver.new source_folder
    output_path = archiver.archive

    File.rename(output_path, test_cbz) if output_path != test_cbz
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'stores absolute path of archive file' do
      expect(extractor.send(:archive_path)).to eq File.expand_path(test_cbz)
    end
  end

  describe '#extract' do
    it 'extracts CBZ file to folder with default .cb extension' do
      extract_path = extractor.extract

      expect(File.exist?(extract_path)).to be true
      expect(File.directory?(extract_path)).to be true
      expect(File.extname(extract_path)).to eq '.cb'
      expect(File.basename(extract_path, '.cb')).to eq 'test'
    end

    it 'extracts to custom destination folder' do
      custom_destination = File.join temp_dir, 'custom_extract'
      extract_path = extractor.extract custom_destination

      expect(extract_path).to eq custom_destination
      expect(File.exist?(custom_destination)).to be true
      expect(File.directory?(custom_destination)).to be true
    end

    it 'uses custom extension when specified' do
      extract_path = extractor.extract nil, extension: :folder

      expect(File.extname(extract_path)).to eq '.folder'
    end

    it 'uses no extension when extension is nil' do
      extract_path = extractor.extract nil, extension: nil

      expect(File.extname(extract_path)).to eq ''
      expect(File.basename(extract_path)).to eq 'test'
    end

    it 'extracts all image files from the archive' do
      extract_path = extractor.extract

      expect(File.exist?(File.join(extract_path, 'page1.jpg'))).to be true
      expect(File.exist?(File.join(extract_path, 'page2.png'))).to be true
      expect(File.exist?(File.join(extract_path, 'page3.gif'))).to be true
    end

    it 'preserves file contents during extraction' do
      extract_path = extractor.extract

      content_one   = File.read File.join(extract_path, 'page1.jpg')
      content_two   = File.read File.join(extract_path, 'page2.png')
      content_three = File.read File.join(extract_path, 'page3.gif')

      expect(content_one).to eq   'image1 content'
      expect(content_two).to eq   'image2 content'
      expect(content_three).to eq 'image3 content'
    end

    it 'handles nested directory structures' do
      # Create CBZ with nested structure
      nested_folder = File.join temp_dir, 'nested_source'
      subfolder     = File.join nested_folder, 'subfolder'

      Dir.mkdir nested_folder
      Dir.mkdir subfolder
      File.write File.join(subfolder, 'nested.jpg'), 'nested content'

      nested_cbz  = File.join temp_dir, 'nested.cbz'
      archiver    = ComicBook::Adapters::CBZArchiver.new nested_folder
      output_path = archiver.archive

      File.rename output_path, nested_cbz

      nested_extractor = described_class.new nested_cbz
      extract_path     = nested_extractor.extract
      nested_image     = File.join extract_path, 'subfolder', 'nested.jpg'

      expect(File.exist?(nested_image)).to be true
      expect(File.read(nested_image)).to eq 'nested content'
    end

    it 'ignores non-image files in the archive' do
      # Create CBZ with mixed file types (manually add non-image files)
      mixed_cbz = File.join(temp_dir, 'mixed.cbz')

      Zip::File.open(mixed_cbz, create: true) do |zipfile|
        zipfile.add 'page1.jpg', File.join(source_folder, 'page1.jpg')
        zipfile.get_output_stream('readme.txt') { |f| f.write 'text content' }
        zipfile.get_output_stream('data.json')  { |f| f.write '{}' }
      end

      mixed_extractor = described_class.new mixed_cbz
      extract_path    = mixed_extractor.extract

      image_in_archive = File.join(extract_path, 'page1.jpg')
      text_file_in_archive = File.join(extract_path, 'readme.txt')
      json_file_inarchive = File.join(extract_path, 'data.json')

      expect(File.exist?(image_in_archive)).to be true
      expect(File.exist?(text_file_in_archive)).to be false
      expect(File.exist?(json_file_inarchive)).to be false
    end

    it 'deletes original archive when delete_original is true' do
      extractor.extract nil, delete_original: true

      expect(File.exist?(test_cbz)).to be false
    end

    it 'preserves original archive when delete_original is false' do
      extractor.extract(nil, delete_original: false)

      expect(File.exist?(test_cbz)).to be true
    end

    it 'returns the path to the extracted folder' do
      extract_path = extractor.extract

      expect(extract_path).to be_a String
      expect(File.exist?(extract_path)).to be true
      expect(File.directory?(extract_path)).to be true
    end

    context 'when archive is empty' do
      subject(:extractor) { described_class.new empty_cbz }

      let(:empty_cbz) { File.join temp_dir, 'empty.cbz' }

      before do
        Zip::File.open(empty_cbz, create: true) do |_zipfile|
          # Intentionally empty archive
        end
      end

      it 'creates empty extraction folder' do
        extract_path = extractor.extract

        expect(File.exist?(extract_path)).to be true
        expect(File.directory?(extract_path)).to be true
        expect(Dir.empty?(extract_path)).to be true
      end
    end

    context 'when archive contains only non-image files' do
      let(:extractor) { described_class.new text_cbz }
      subject(:extractor_path) { extractor.extract }

      let(:text_cbz) { File.join temp_dir, 'text_only.cbz' }

      before do
        Zip::File.open(text_cbz, create: true) do |zipfile|
          zipfile.get_output_stream('readme.txt') { |f| f.write('text content') }
          zipfile.get_output_stream('config.json') { |f| f.write('{}') }
        end
      end

      it 'creates empty extraction folder' do
        expect(File.exist?(extractor_path)).to be true
        expect(File.directory?(extractor_path)).to be true
        expect(Dir.empty?(extractor_path)).to be true
      end
    end

    context 'when destination folder already exists' do
      let(:existing_destination) { File.join temp_dir, 'existing' }
      let(:image_in_archive)     { File.join existing_destination, 'page1.jpg' }
      let(:old_file)             { File.join existing_destination, 'old_file.txt' }

      before do
        Dir.mkdir existing_destination
        File.write old_file, 'old content'
      end

      it 'extracts into existing folder' do
        extract_path = extractor.extract(existing_destination)

        expect(extract_path).to eq existing_destination
        expect(File.exist?(image_in_archive)).to be true
        expect(File.exist?(old_file)).to be true
      end
    end
  end
end
