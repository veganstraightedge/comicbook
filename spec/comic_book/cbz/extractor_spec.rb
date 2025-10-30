require 'spec_helper'

RSpec.describe ComicBook::CBZ::Extractor do
  subject(:extractor) { described_class.new test_cbz }

  let(:temp_dir)      { Dir.mktmpdir }
  let(:source_folder) { File.join temp_dir, 'source' }
  let(:test_cbz)      { File.join temp_dir, 'test.cbz' }
  let(:archiver)      { ComicBook::CBZ::Archiver.new source_folder }

  before do
    Dir.mkdir source_folder
    File.write File.join(source_folder, 'page1.jpg'), 'image1 content'
    File.write File.join(source_folder, 'page2.png'), 'image2 content'
    File.write File.join(source_folder, 'page3.gif'), 'image3 content'

    # Create a real CBZ file using CBZ::Archiver
    output_path = archiver.archive
    File.rename(output_path, test_cbz) if output_path != test_cbz
  end

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    it 'stores absolute path of archive file' do
      expect(extractor.send(:archive_path)).to eq File.expand_path(test_cbz)
    end
  end

  describe '#extract' do
    context 'with default .cb extension' do
      it 'extracts CBZ file to folder' do
        extracted_folder_path = extractor.extract

        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(File.extname(extracted_folder_path)).to eq '.cb'
        expect(File.basename(extracted_folder_path, '.cb')).to eq 'test'
      end
    end

    context 'with non-default destination folder' do
      it 'extracts to custom destination folder' do
        custom_destination_path = File.join temp_dir, 'custom_destination_path_folder'
        extracted_folder_path   = extractor.extract custom_destination_path

        expect(extracted_folder_path).to eq custom_destination_path
        expect(File).to exist custom_destination_path
        expect(File).to be_directory custom_destination_path
      end
    end

    context 'with non-default folder extension' do
      it 'extracts to a folder with custom extension' do
        extracted_folder_path = extractor.extract nil, extension: :comicbook

        expect(File.extname(extracted_folder_path)).to eq '.comicbook'
      end
    end

    context 'with no folder extension' do
      it 'uses no extension when extension is nil' do
        extracted_folder_path = extractor.extract nil, extension: nil

        expect(File.extname(extracted_folder_path)).to be_empty
        expect(File.basename(extracted_folder_path)).to eq 'test'
      end
    end

    context 'with images in archive' do
      let(:image_a) { File.join extracted_folder_path, 'page1.jpg' }
      let(:image_b) { File.join extracted_folder_path, 'page2.png' }
      let(:image_c) { File.join extracted_folder_path, 'page3.gif' }
      let(:extracted_folder_path) { extractor.extract }

      it 'extracts all image files from the archive' do
        expect(File).to exist image_a
        expect(File).to exist image_b
        expect(File).to exist image_c
      end

      it 'preserves file contents during extraction' do
        expect(File.read(image_a)).to eq 'image1 content'
        expect(File.read(image_b)).to eq 'image2 content'
        expect(File.read(image_c)).to eq 'image3 content'
      end
    end

    context 'with nested directories' do
      subject(:nested_image) { File.join subfolder, 'nested.jpg' }

      let(:nested_folder)         { File.join temp_dir,      'nested_source' }
      let(:subfolder)             { File.join nested_folder, 'subfolder' }
      let(:nested_cbz)            { File.join temp_dir,      'nested.cbz' }
      let(:nested_extractor)      { described_class.new nested_cbz }
      let(:extracted_folder_path) { nested_extractor.extract }
      let(:archiver)              { ComicBook::CBZ::Archiver.new nested_folder }
      let(:output_path)           { archiver.archive }

      before do
        Dir.mkdir nested_folder
        Dir.mkdir subfolder
        File.write nested_image, 'nested content'
        File.rename output_path, nested_cbz
      end

      it 'handles nested directory structures' do
        expect(File).to exist nested_image
        expect(File.read(nested_image)).to eq 'nested content'
      end
    end

    context 'with non-images in the archive' do
      let(:mixed_cbz)             { File.join temp_dir, 'mixed.cbz' }
      let(:mixed_extractor)       { described_class.new mixed_cbz }
      let(:extracted_folder_path) { mixed_extractor.extract }
      let(:image_in_archive)      { File.join extracted_folder_path, 'page1.jpg' }
      let(:text_file_in_archive)  { File.join extracted_folder_path, 'readme.txt' }
      let(:json_file_inarchive)   { File.join extracted_folder_path, 'data.json' }

      before do
        Zip::File.open(mixed_cbz, create: true) do |zipfile|
          zipfile.add 'page1.jpg', File.join(source_folder, 'page1.jpg')
          zipfile.get_output_stream('readme.txt') { |f| f.write 'text content' }
          zipfile.get_output_stream('data.json')  { |f| f.write '{}' }
        end
      end

      it 'ignores non-image files' do
        expect(File).to exist image_in_archive
        expect(File).not_to exist text_file_in_archive
        expect(File).not_to exist json_file_inarchive
      end
    end

    context 'when delete_original is true' do
      it 'deletes original archive' do
        extractor.extract nil, delete_original: true

        expect(File).not_to exist test_cbz
      end
    end

    context 'when delete_original is false' do
      it 'preserves original archive' do
        extractor.extract nil, delete_original: false

        expect(File).to exist test_cbz
      end
    end

    context 'when no args are set' do
      subject(:extracted_folder_path) { extractor.extract }

      it 'returns the path to the extracted folder' do
        expect(extracted_folder_path).to be_a String
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
      end
    end

    context 'when archive is empty' do
      subject(:extracted_folder_path) { extractor.extract }

      let(:extractor) { described_class.new empty_cbz }
      let(:empty_cbz) { File.join temp_dir, 'empty.cbz' }

      before do
        Zip::File.open(empty_cbz, create: true) do |_zipfile|
          # Intentionally empty archive
        end
      end

      it 'creates empty extraction folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(Dir).to be_empty extracted_folder_path
      end
    end

    context 'when archive contains only non-image files' do
      subject(:extractor_path) { extractor.extract }

      let(:extractor) { described_class.new text_cbz }
      let(:text_cbz)  { File.join temp_dir, 'text_only.cbz' }

      before do
        Zip::File.open(text_cbz, create: true) do |zipfile|
          zipfile.get_output_stream('readme.txt')  { |f| f.write('text content') }
          zipfile.get_output_stream('config.json') { |f| f.write('{}') }
        end
      end

      it 'creates empty extraction folder' do
        expect(File).to exist extractor_path
        expect(File).to be_directory extractor_path
        expect(Dir).to be_empty extractor_path
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
        extracted_folder_path = extractor.extract existing_destination

        expect(extracted_folder_path).to eq existing_destination
        expect(File).to exist image_in_archive
        expect(File).to exist old_file
      end
    end
  end
end
