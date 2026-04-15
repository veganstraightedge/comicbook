require 'spec_helper'

RSpec.describe ComicBook::PDF::Extractor do
  subject(:extractor) { described_class.new test_pdf }

  let(:temp_dir) { Dir.mktmpdir }
  let(:extracted_folder_path) { extractor.extract }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:test_pdf) { File.join temp_dir, 'simple.pdf' }

    before do
      load_fixture('pdf/simple.pdf').copy_to test_pdf
    end

    it 'stores absolute path of PDF file' do
      expect(extractor.send(:pdf_path)).to eq File.expand_path(test_pdf)
    end
  end

  describe '#extract' do
    let(:test_pdf) { File.join temp_dir, 'simple.pdf' }

    before do
      load_fixture('pdf/simple.pdf').copy_to test_pdf
    end

    context 'with default .cb extension' do
      it 'extracts PDF pages to folder' do
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

    context 'with rendered pages' do
      let(:image_a) { File.join extracted_folder_path, 'page_001.jpg' }
      let(:image_b) { File.join extracted_folder_path, 'page_002.jpg' }
      let(:image_c) { File.join extracted_folder_path, 'page_003.jpg' }

      it 'renders all pages as JPEG images' do
        expect(File).to exist image_a
        expect(File).to exist image_b
        expect(File).to exist image_c
      end

      it 'creates valid JPEG files' do
        extracted_folder_path

        [image_a, image_b, image_c].each do |image|
          expect(File.size(image)).to be > 0
        end
      end
    end

    context 'with single page PDF' do
      let(:test_pdf) { File.join temp_dir, 'single_page.pdf' }
      let(:image_a) { File.join extracted_folder_path, 'page_001.jpg' }

      before do
        load_fixture('pdf/single_page.pdf').copy_to test_pdf
      end

      it 'renders one page' do
        expect(File).to exist image_a
        expect(Dir.glob(File.join(extracted_folder_path, '*.jpg')).length).to eq 1
      end
    end

    context 'with empty PDF' do
      let(:test_pdf) { File.join temp_dir, 'empty.pdf' }

      before do
        load_fixture('pdf/empty.pdf').copy_to test_pdf
      end

      it 'creates empty destination folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
        expect(Dir.glob(File.join(extracted_folder_path, '*'))).to be_empty
      end
    end

    context 'when delete_original is true' do
      before do
        extractor.extract delete_original: true
      end

      it 'deletes original PDF' do
        expect(File).not_to exist test_pdf
      end
    end

    context 'when delete_original is false' do
      before do
        extractor.extract delete_original: false
      end

      it 'preserves original PDF' do
        expect(File).to exist test_pdf
      end
    end

    context 'when no args are set' do
      it 'returns the path to the extracted folder' do
        expect(extracted_folder_path).to be_a String
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
      end
    end

    context 'with default DPI' do
      let(:image_a) { File.join extracted_folder_path, 'page_001.jpg' }

      it 'renders pages at 300 DPI' do
        extracted_folder_path

        image = Vips::Image.new_from_file image_a
        expect(image.width).to be > 1000
      end
    end

    context 'with custom dpi: 72' do
      let(:extracted_folder_path) { extractor.extract dpi: 72 }
      let(:image_a) { File.join extracted_folder_path, 'page_001.jpg' }

      it 'renders pages at lower resolution' do
        extracted_folder_path

        image = Vips::Image.new_from_file image_a
        expect(image.width).to be < 500
      end
    end

    context 'with custom dpi: 600' do
      let(:extracted_folder_path) { extractor.extract dpi: 600 }
      let(:image_a) { File.join extracted_folder_path, 'page_001.jpg' }

      it 'renders pages at higher resolution' do
        extracted_folder_path

        image = Vips::Image.new_from_file image_a
        expect(image.width).to be > 3000
      end
    end

    context 'when destination folder already exists' do
      let(:existing_destination) { File.join temp_dir, 'existing' }
      let(:image_in_folder) { File.join existing_destination, 'page_001.jpg' }
      let(:old_file) { File.join existing_destination, 'old_file.txt' }
      let(:extracted_folder_path) { extractor.extract to: existing_destination }

      before do
        Dir.mkdir existing_destination
        File.write old_file, 'old content'
      end

      it 'extracts into existing folder' do
        expect(extracted_folder_path).to eq existing_destination
        expect(File).to exist image_in_folder
        expect(File).to exist old_file
      end
    end
  end
end
