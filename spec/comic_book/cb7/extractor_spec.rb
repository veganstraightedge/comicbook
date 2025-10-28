require 'spec_helper'

RSpec.describe ComicBook::CB7::Extractor do
  subject(:extractor) { described_class.new(test_cb7) }

  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:test_cb7) { File.join(temp_dir, 'simple.cb7') }

    before do
      load_fixture('cb7/simple.cb7').copy_to test_cb7
    end

    it 'stores absolute path of archive file' do
      expect(extractor.send(:archive_path)).to eq File.expand_path(test_cb7)
    end
  end

  describe '#extract' do
    let(:test_cb7) { File.join(temp_dir, 'simple.cb7') }

    before do
      load_fixture('cb7/simple.cb7').copy_to test_cb7
    end

    context 'with default .cb extension' do
      let(:extracted_folder_path) { extractor.extract }

      it 'extracts CB7 file to folder' do
        expect(File.exist?(extracted_folder_path)).to be true
        expect(File.directory?(extracted_folder_path)).to be true
        expect(File.extname(extracted_folder_path)).to eq '.cb'
        expect(File.basename(extracted_folder_path, '.cb')).to eq 'simple'
      end
    end

    context 'with non-default destination folder' do
      let(:extracted_folder_path) { extractor.extract custom_destination_path }
      let(:custom_destination_path) { File.join(temp_dir, 'custom_destination') }

      it 'extracts to custom destination folder' do
        expect(extracted_folder_path).to eq custom_destination_path
        expect(File.exist?(custom_destination_path)).to be true
        expect(File.directory?(custom_destination_path)).to be true
      end
    end

    context 'with non-default folder extension' do
      let(:extracted_folder_path) { extractor.extract(nil, extension: :comicbook) }

      it 'extracts to a folder with custom extension' do
        expect(File.extname(extracted_folder_path)).to eq '.comicbook'
      end
    end

    context 'with no folder extension' do
      let(:extracted_folder_path) { extractor.extract(nil, extension: nil) }

      it 'uses no extension when extension is nil' do
        expect(File.extname(extracted_folder_path)).to eq ''
        expect(File.basename(extracted_folder_path)).to eq 'simple'
      end
    end

    context 'with images in archive' do
      let(:extracted_folder_path) { extractor.extract }
      let(:image_a) { File.join(extracted_folder_path, 'page1.jpg') }
      let(:image_b) { File.join(extracted_folder_path, 'page2.png') }
      let(:image_c) { File.join(extracted_folder_path, 'page3.gif') }

      it 'extracts all image files from the archive' do
        expect(File.exist?(image_a)).to be true
        expect(File.exist?(image_b)).to be true
        expect(File.exist?(image_c)).to be true
      end

      it 'preserves file contents during extraction' do
        expect(File.exist?(image_a)).to be true
        expect(File.exist?(image_b)).to be true
        expect(File.exist?(image_c)).to be true
      end
    end

    context 'with nested directories' do
      let(:test_cb7) { File.join(temp_dir, 'nested.cb7') }
      let(:extracted_folder_path) { extractor.extract }
      let(:nested_image) { File.join(extracted_folder_path, 'subfolder', 'nested.jpg') }

      before do
        load_fixture('cb7/nested.cb7').copy_to test_cb7
      end

      it 'handles nested directory structures' do
        expect(File.exist?(nested_image)).to be true
      end
    end

    context 'with non-images in the archive' do
      let(:test_cb7) { File.join(temp_dir, 'mixed.cb7') }
      let(:extracted_folder_path) { extractor.extract }
      let(:image_in_archive) { File.join(extracted_folder_path, 'page1.jpg') }
      let(:text_file_in_archive) { File.join(extracted_folder_path, 'readme.txt') }
      let(:json_file_in_archive) { File.join(extracted_folder_path, 'data.json') }

      before do
        load_fixture('cb7/mixed.cb7').copy_to test_cb7
      end

      it 'ignores non-image files' do
        expect(File.exist?(image_in_archive)).to be true
        expect(File.exist?(text_file_in_archive)).to be false
        expect(File.exist?(json_file_in_archive)).to be false
      end
    end

    context 'when delete_original is true' do
      it 'deletes original archive' do
        extractor.extract(nil, delete_original: true)

        expect(File.exist?(test_cb7)).to be false
      end
    end

    context 'when delete_original is false' do
      it 'preserves original archive' do
        extractor.extract(nil, delete_original: false)

        expect(File.exist?(test_cb7)).to be true
      end
    end

    context 'when no args are set' do
      subject(:extracted_folder_path) { extractor.extract }

      it 'returns the path to the extracted folder' do
        expect(extracted_folder_path).to be_a String
        expect(File.exist?(extracted_folder_path)).to be true
        expect(File.directory?(extracted_folder_path)).to be true
      end
    end

    context 'when archive is empty' do
      subject(:extracted_folder_path) { extractor.extract }

      let(:extractor) { described_class.new(test_cb7) }
      let(:test_cb7) { File.join(temp_dir, 'empty.cb7') }

      before do
        load_fixture('cb7/empty.cb7').copy_to test_cb7
      end

      it 'creates empty extraction folder' do
        expect(File.exist?(extracted_folder_path)).to be true
        expect(File.directory?(extracted_folder_path)).to be true
        expect(Dir.empty?(extracted_folder_path)).to be true
      end
    end

    context 'when archive contains only non-image files' do
      subject(:extracted_folder_path) { extractor.extract }

      let(:extractor) { described_class.new(test_cb7) }
      let(:test_cb7) { File.join(temp_dir, 'text_only.cb7') }

      before do
        load_fixture('cb7/text_only.cb7').copy_to test_cb7
      end

      it 'creates empty extraction folder' do
        expect(File.exist?(extracted_folder_path)).to be true
        expect(File.directory?(extracted_folder_path)).to be true
        expect(Dir.empty?(extracted_folder_path)).to be true
      end
    end

    context 'when destination folder already exists' do
      let(:existing_destination) { File.join(temp_dir, 'existing') }
      let(:image_in_archive) { File.join(existing_destination, 'page1.jpg') }
      let(:old_file) { File.join(existing_destination, 'old_file.txt') }

      before do
        Dir.mkdir(existing_destination)
        File.write(old_file, 'old content')
      end

      it 'extracts into existing folder' do
        extracted_folder_path = extractor.extract(existing_destination)

        expect(extracted_folder_path).to eq existing_destination
        expect(File.exist?(image_in_archive)).to be true
        expect(File.exist?(old_file)).to be true
      end
    end
  end
end
