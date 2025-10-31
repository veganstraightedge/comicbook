require 'spec_helper'

RSpec.describe ComicBook::CBZ do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_cbz) }

    let(:test_cbz) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to(test_cbz)
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cbz)
    end
  end

  describe '#archive' do
    let(:source_folder) { File.join temp_dir, 'source' }
    let(:adapter) { described_class.new source_folder }

    before do
      load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
      load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
      load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
    end

    it 'creates a CBZ file from source folder' do
      output_path = adapter.archive source_folder

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cbz'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive source_folder

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
      end
    end

    it 'deletes original folder when delete_original is true' do
      adapter.archive source_folder, delete_original: true
      expect(File).not_to exist source_folder
    end

    it 'preserves original folder when delete_original is false' do
      adapter.archive source_folder, delete_original: false
      expect(File).to exist source_folder
    end

    it 'uses custom extension when specified' do
      output_path = adapter.archive source_folder, extension: :zip
      expect(File.extname(output_path)).to eq '.zip'
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new test_cbz }

    let(:test_cbz) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to test_cbz
    end

    it 'extracts CBZ file to folder' do
      extract_path = adapter.extract

      expect(File).to exist extract_path
      expect(File).to be_directory extract_path

      expect(File).to exist File.join(extract_path, 'simple', 'page1.jpg')
      expect(File).to exist File.join(extract_path, 'simple', 'page2.png')
      expect(File).to exist File.join(extract_path, 'simple', 'page3.gif')
    end

    it 'uses .cb extension by default' do
      extract_path = adapter.extract
      expect(File.extname(extract_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extract_path = adapter.extract nil, extension: :folder
      expect(File.extname(extract_path)).to eq '.folder'
    end

    it 'uses no extension when extension is nil' do
      extract_path = adapter.extract nil, extension: nil
      expect(File.extname(extract_path)).to be_empty
    end

    it 'extracts to custom destination when specified' do
      custom_dest = File.join temp_dir, 'custom_extract'
      extract_path = adapter.extract custom_dest

      expect(extract_path).to eq custom_dest
      expect(File).to exist custom_dest
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract nil, delete_original: true
      expect(File).not_to exist test_cbz
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract nil, delete_original: false
      expect(File).to exist test_cbz
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new test_cbz }

    let(:test_cbz) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to test_cbz
    end

    it 'returns array of Page objects' do
      pages = adapter.pages

      expect(pages).to all(be_a(ComicBook::Page))
      expect(pages.length).to eq 3
    end

    it 'sorts pages alphabetically by name' do
      pages = adapter.pages

      expect(pages.map(&:name)).to eq %w[page1.jpg page2.png page3.gif]
    end

    it 'sets correct path and name for each page' do
      pages = adapter.pages

      expect(pages.first.path).to eq 'simple/page1.jpg'
      expect(pages.first.name).to eq 'page1.jpg'
    end

    context 'with non-image files in the archive' do
      subject(:adapter) { described_class.new mixed_cbz }

      let(:mixed_cbz) { File.join temp_dir, 'mixed.cbz' }

      before do
        load_fixture('cbz/mixed.cbz').copy_to mixed_cbz
      end

      it 'only includes image files' do
        pages = adapter.pages
        names = pages.map(&:name)

        expect(names).to include('page1.jpg')
        expect(names).not_to include('readme.txt')
      end
    end
  end
end
