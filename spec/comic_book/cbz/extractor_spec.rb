require 'spec_helper'

RSpec.describe ComicBook::CBZ::Extractor do
  subject(:extractor) { described_class.new test_cbz }

  let(:temp_dir) { Dir.mktmpdir }
  let(:extracted_folder_path) { extractor.extract }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:test_cbz) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to test_cbz
    end

    it 'stores absolute path of archive file' do
      expect(extractor.send(:archive_path)).to eq File.expand_path(test_cbz)
    end
  end

  describe '#extract' do
    let(:test_cbz) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to test_cbz
    end

    context 'with default .cb extension' do
      it 'extracts CBZ file to folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(File.extname(extracted_folder_path)).to eq '.cb'
        expect(File.basename(extracted_folder_path, '.cb')).to eq 'simple'
      end
    end

    context 'with non-default destination folder' do
      let(:extracted_folder_path) { extractor.extract to: custom_destination_path }
      let(:custom_destination_path) { File.join temp_dir, 'custom_destination' }

      it 'extracts to custom destination folder' do
        expect(extracted_folder_path).to eq custom_destination_path
        expect(File).to exist custom_destination_path
        expect(File).to be_directory custom_destination_path
      end
    end

    context 'with non-default folder extension' do
      let(:extracted_folder_path) { extractor.extract extension: :comicbook }

      it 'extracts to a folder with custom extension' do
        expect(File.extname(extracted_folder_path)).to eq '.comicbook'
      end
    end

    context 'with no folder extension' do
      let(:extracted_folder_path) { extractor.extract extension: nil }

      it 'uses no extension when extension is nil' do
        expect(File.extname(extracted_folder_path)).to be_empty
        expect(File.basename(extracted_folder_path)).to eq 'simple'
      end
    end

    context 'with images in archive' do
      let(:image_a) { File.join extracted_folder_path, 'simple', 'page1.jpg' }
      let(:image_b) { File.join extracted_folder_path, 'simple', 'page2.png' }
      let(:image_c) { File.join extracted_folder_path, 'simple', 'page3.gif' }

      it 'extracts all image files from the archive' do
        expect(File).to exist image_a
        expect(File).to exist image_b
        expect(File).to exist image_c
      end

      it 'preserves file contents during extraction' do
        original_content_a = File.read(load_fixture('originals/simple/page1.jpg').path, mode: 'rb')
        original_content_b = File.read(load_fixture('originals/simple/page2.png').path, mode: 'rb')
        original_content_c = File.read(load_fixture('originals/simple/page3.gif').path, mode: 'rb')

        expect(File.read(image_a, mode: 'rb')).to eq original_content_a
        expect(File.read(image_b, mode: 'rb')).to eq original_content_b
        expect(File.read(image_c, mode: 'rb')).to eq original_content_c
      end
    end

    context 'with nested directories' do
      subject(:extractor) { described_class.new nested_cbz }

      let(:nested_cbz) { File.join temp_dir, 'nested.cbz' }
      let(:extracted_folder_path) { extractor.extract }
      let(:nested_image) { File.join extracted_folder_path, 'nested', 'subfolder', 'nested.jpg' }

      before do
        load_fixture('cbz/nested.cbz').copy_to nested_cbz
      end

      it 'handles nested directory structures' do
        expect(File).to exist nested_image
        original_content = File.read(load_fixture('originals/nested/subfolder/nested.jpg').path, mode: 'rb')
        expect(File.read(nested_image, mode: 'rb')).to eq original_content
      end
    end

    context 'with non-images in the archive' do
      subject(:extractor) do
        described_class
          .new mixed_cbz
      end

      let(:mixed_cbz) { File.join temp_dir, 'mixed.cbz' }
      let(:extracted_folder_path) { extractor.extract }
      let(:image_in_archive) { File.join extracted_folder_path, 'mixed', 'page1.jpg' }
      let(:text_file_in_archive) { File.join extracted_folder_path, 'mixed', 'readme.txt' }
      let(:json_file_in_archive) { File.join extracted_folder_path, 'mixed', 'data.json' }

      before do
        load_fixture('cbz/mixed.cbz').copy_to mixed_cbz
      end

      it 'ignores non-image files' do
        expect(File).to exist image_in_archive
        expect(File).not_to exist text_file_in_archive
        expect(File).not_to exist json_file_in_archive
      end
    end

    context 'when delete_original is true' do
      it 'deletes original archive' do
        extractor.extract delete_original: true

        expect(File).not_to exist test_cbz
      end
    end

    context 'when delete_original is false' do
      it 'preserves original archive' do
        extractor.extract delete_original: false

        expect(File).to exist test_cbz
      end
    end

    context 'when no args are set' do
      it 'returns the path to the extracted folder' do
        expect(extracted_folder_path).to be_a String
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
      end
    end

    context 'when archive is empty' do
      subject(:extractor) { described_class.new empty_cbz }

      let(:empty_cbz) { File.join temp_dir, 'empty.cbz' }
      let(:extracted_folder_path) { extractor.extract }

      before do
        load_fixture('cbz/empty.cbz').copy_to empty_cbz
      end

      it 'creates empty extraction folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(Dir).to be_empty extracted_folder_path
      end
    end

    context 'when archive contains only non-image files' do
      subject(:extractor) { described_class.new text_cbz }

      let(:text_cbz) { File.join temp_dir, 'text_only.cbz' }
      let(:extracted_folder_path) { extractor.extract }

      before do
        load_fixture('cbz/text_only.cbz').copy_to text_cbz
      end

      it 'creates empty extraction folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(Dir).to be_empty extracted_folder_path
      end
    end

    context 'when destination folder already exists' do
      let(:existing_destination) { File.join temp_dir, 'existing' }
      let(:extracted_folder_path) { extractor.extract to: existing_destination }
      let(:image_in_archive) { File.join existing_destination, 'simple', 'page1.jpg' }
      let(:old_file) { File.join existing_destination, 'old_file.txt' }

      before do
        Dir.mkdir existing_destination
        File.write old_file, 'old content'
      end

      it 'extracts into existing folder' do
        expect(extracted_folder_path).to eq existing_destination
        expect(File).to exist image_in_archive
        expect(File).to exist old_file
      end
    end
  end
end
