require 'spec_helper'

RSpec.describe ComicBook::PDF do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_pdf) }

    let(:test_pdf) { File.join(temp_dir, 'simple.pdf') }

    before do
      load_fixture('pdf/simple.pdf').copy_to(test_pdf)
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_pdf)
    end
  end

  describe '#archive' do
    let(:test_pdf) { File.join(temp_dir, 'simple.pdf') }
    let(:adapter) { described_class.new test_pdf }

    before do
      load_fixture('pdf/simple.pdf').copy_to(test_pdf)
    end

    it 'raises error because PDF archiving is not supported' do
      expect { adapter.archive }.to raise_error(ComicBook::Error, /not supported/)
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(test_pdf) }

    let(:test_pdf) { File.join(temp_dir, 'simple.pdf') }

    before do
      load_fixture('pdf/simple.pdf').copy_to(test_pdf)
    end

    it 'extracts PDF pages to folder' do
      extracted_path = adapter.extract

      expect(File).to exist extracted_path
      expect(File).to be_directory extracted_path
    end

    it 'uses .cb extension by default' do
      extracted_path = adapter.extract

      expect(File.extname(extracted_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extracted_path = adapter.extract extension: :comicbook

      expect(File.extname(extracted_path)).to eq '.comicbook'
    end

    it 'uses no extension when extension is nil' do
      extracted_path = adapter.extract extension: nil

      expect(File.extname(extracted_path)).to be_empty
    end

    it 'extracts to custom destination when specified' do
      custom_destination = File.join temp_dir, 'custom'
      extracted_path = adapter.extract to: custom_destination

      expect(extracted_path).to eq custom_destination
      expect(File).to exist custom_destination
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract delete_original: true

      expect(File).not_to exist test_pdf
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract delete_original: false

      expect(File).to exist test_pdf
    end

    it 'renders each page as a JPEG image' do
      extracted_path = adapter.extract

      images = Dir.glob(File.join(extracted_path, '*.jpg'))
      expect(images.length).to eq 3
      expect(images.map { File.basename it }).to eq %w[page_001.jpg page_002.jpg page_003.jpg]
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new(test_pdf) }

    let(:test_pdf) { File.join(temp_dir, 'simple.pdf') }

    before do
      load_fixture('pdf/simple.pdf').copy_to(test_pdf)
    end

    it 'returns array of Page objects' do
      pages = adapter.pages

      expect(pages).to be_all ComicBook::Page
      expect(pages.length).to eq 3
    end

    it 'names pages sequentially' do
      pages = adapter.pages

      expect(pages.map(&:name)).to eq %w[page_001.jpg page_002.jpg page_003.jpg]
    end

    it 'sets correct path and name for each page' do
      pages = adapter.pages

      expect(pages.first.path).to eq 'page_001.jpg'
      expect(pages.first.name).to eq 'page_001.jpg'
    end

    context 'with single page PDF' do
      let(:test_pdf) { File.join(temp_dir, 'single_page.pdf') }

      before do
        load_fixture('pdf/single_page.pdf').copy_to(test_pdf)
      end

      it 'returns one page' do
        pages = adapter.pages

        expect(pages.length).to eq 1
        expect(pages.first.name).to eq 'page_001.jpg'
      end
    end
  end
end
