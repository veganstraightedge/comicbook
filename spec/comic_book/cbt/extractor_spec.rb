require 'spec_helper'

RSpec.describe ComicBook::CBT::Extractor do
  subject(:extractor) { described_class.new test_cbt }

  let(:temp_dir) { Dir.mktmpdir }
  let(:extracted_folder_path) { extractor.extract }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:test_cbt) { File.join temp_dir, 'simple.cbt' }

    before do
      load_fixture('cbt/simple.cbt').copy_to test_cbt
    end

    it 'stores absolute path of archive file' do
      expect(extractor.send(:path)).to eq File.expand_path(test_cbt)
    end
  end

  describe '#extract' do
    let(:test_cbt) { File.join temp_dir, 'simple.cbt' }

    before do
      load_fixture('cbt/simple.cbt').copy_to test_cbt
    end

    context 'with default .cb extension' do
      it 'extracts CBT file to folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(File.extname(extracted_folder_path)).to eq '.cb'
        expect(File.basename(extracted_folder_path, '.cb')).to eq 'simple'
      end
    end

    context 'with non-default destination folder' do
      let(:extracted_folder_path) { extractor.extract destination: custom_destination_path }
      let(:custom_destination_path) { File.join temp_dir, 'custom_destination' }

      it 'extracts to custom destination folder' do
        expect(extracted_folder_path).to eq custom_destination_path
        expect(File).to exist custom_destination_path
        expect(File).to be_directory custom_destination_path
      end
    end

    context 'with non-default folder extension' do
      it 'extracts to a folder with custom extension' do
        extracted_folder_path = extractor.extract extension: :comicbook

        expect(File.extname(extracted_folder_path)).to eq '.comicbook'
      end
    end

    context 'with no folder extension' do
      it 'uses no extension when extension is nil' do
        extracted_folder_path = extractor.extract extension: nil

        expect(File.extname(extracted_folder_path)).to eq ''
      end
    end

    context 'with images in archive' do
      it 'extracts all image files from the archive' do
        image_files = Dir.glob File.join(extracted_folder_path, ComicBook::IMAGE_GLOB_PATTERN)

        expect(image_files.length).to be_positive
        expect(image_files.map { File.basename(it) }).to include('page1.jpg', 'page2.png', 'page3.gif')
      end

      it 'preserves file contents during extraction' do
        extracted_file = File.join extracted_folder_path, 'page1.jpg'
        expected_content = File.binread(load_fixture('originals/simple/page1.jpg').path)

        expect(File).to exist extracted_file
        expect(File.binread(extracted_file)).to eq expected_content
      end
    end

    context 'with nested directories' do
      let(:test_cbt) { File.join temp_dir, 'nested.cbt' }

      before do
        load_fixture('cbt/nested.cbt').copy_to test_cbt
      end

      it 'handles nested directory structures' do
        nested_file = File.join extracted_folder_path, 'subfolder', 'nested.jpg'

        expect(File).to exist nested_file
        expect(File.basename(nested_file)).to eq 'nested.jpg'
      end
    end

    context 'with non-images in the archive' do
      let(:test_cbt) { File.join temp_dir, 'mixed.cbt' }

      before do
        load_fixture('cbt/mixed.cbt').copy_to test_cbt
      end

      it 'ignores non-image files' do
        text_file = File.join extracted_folder_path, 'readme.txt'

        expect(File).not_to exist text_file
      end
    end

    context 'when delete_original is true' do
      it 'deletes original archive' do
        extractor.extract delete_original: true
        expect(File).not_to exist test_cbt
      end
    end

    context 'when delete_original is false' do
      it 'preserves original archive' do
        extractor.extract delete_original: false
        expect(File).to exist test_cbt
      end
    end

    context 'when no args are set' do
      it 'returns the path to the extracted folder' do
        expect(extracted_folder_path).to be_a String
        expect(File).to be_directory extracted_folder_path
      end
    end

    context 'when archive is empty' do
      let(:test_cbt) { File.join temp_dir, 'empty.cbt' }

      before do
        load_fixture('cbt/empty.cbt').copy_to test_cbt
      end

      it 'creates empty extraction folder' do
        expect(File).to be_directory extracted_folder_path
        expect(Dir.children(extracted_folder_path)).to be_empty
      end
    end

    context 'when archive contains only non-image files' do
      let(:test_cbt) { File.join temp_dir, 'text_only.cbt' }

      before do
        load_fixture('cbt/text_only.cbt').copy_to test_cbt
      end

      it 'creates empty extraction folder' do
        expect(File).to be_directory extracted_folder_path
        expect(Dir.children(extracted_folder_path)).to be_empty
      end
    end

    context 'when destination folder already exists' do
      it 'extracts into existing folder' do
        existing_folder = File.join temp_dir, 'existing'
        Dir.mkdir existing_folder

        extraction_path = extractor.extract destination: existing_folder

        expect(extraction_path).to eq existing_folder
        image_files = Dir.glob File.join(existing_folder, '*.{jpg,png,gif}')
        expect(image_files.length).to be_positive
      end
    end
  end
end
