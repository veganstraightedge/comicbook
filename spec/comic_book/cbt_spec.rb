require 'spec_helper'

RSpec.describe ComicBook::CBT do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_cbt) }

    let(:test_cbt) { File.join(temp_dir, 'simple.cbt') }

    before do
      load_fixture('cbt/simple.cbt').copy_to(test_cbt)
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cbt)
    end
  end

  describe '#archive' do
    let(:source_folder) { File.join(temp_dir, 'source') }
    let(:adapter) { described_class.new source_folder }

    before do
      load_fixture('cbt/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
      load_fixture('cbt/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
      load_fixture('cbt/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
    end

    it 'creates a CBT file from source folder' do
      output_path = adapter.archive source_folder

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cbt'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive source_folder

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entries = tar.map { it.full_name if it.file? }.compact
          expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
        end
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
      output_path = adapter.archive source_folder, extension: :comicbook

      expect(File.extname(output_path)).to eq '.comicbook'
    end
  end

  describe '#extract' do
    subject(:adapter) do
      described_class.new test_cbt
    end

    let(:test_cbt) { File.join temp_dir, 'simple.cbt' }

    before do
      load_fixture('cbt/simple.cbt').copy_to test_cbt
    end

    it 'extracts CBT file to folder' do
      extract_path = adapter.extract

      expect(File).to exist extract_path
      expect(File).to be_directory extract_path

      expect(File).to exist File.join(extract_path, 'page1.jpg')
      expect(File).to exist File.join(extract_path, 'page2.png')
      expect(File).to exist File.join(extract_path, 'page3.gif')
    end

    it 'uses .cb extension by default' do
      extract_path = adapter.extract

      expect(File.extname(extract_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extract_path = adapter.extract nil, extension: :comicbook

      expect(File.extname(extract_path)).to eq '.comicbook'
    end

    it 'uses no extension when extension is nil' do
      extract_path = adapter.extract nil, extension: nil

      expect(File.extname(extract_path)).to eq ''
    end

    it 'extracts to custom destination when specified' do
      custom_dest = File.join temp_dir, 'custom_extraction'
      extract_path = adapter.extract custom_dest

      expect(extract_path).to eq custom_dest
      expect(File).to be_directory custom_dest
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract nil, delete_original: true
      expect(File).not_to exist test_cbt
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract nil, delete_original: false
      expect(File).to exist test_cbt
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new test_cbt }

    let(:test_cbt) { File.join temp_dir, 'simple.cbt' }

    before do
      load_fixture('cbt/simple.cbt').copy_to test_cbt
    end

    it 'returns array of Page objects' do
      pages = adapter.pages

      expect(pages).to be_an Array
      expect(pages).to be_all ComicBook::Page
    end

    it 'sorts pages alphabetically by name' do
      pages = adapter.pages
      names = pages.map(&:name)

      expect(names).to eq names.sort
    end

    it 'sets correct path and name for each page' do
      pages = adapter.pages
      page = pages.first

      expect(page.path).to be_a String
      expect(page.name).to be_a String
    end

    context 'with non-image files in the archive' do
      let(:test_cbt) { File.join temp_dir, 'mixed.cbt' }

      before do
        load_fixture('cbt/mixed.cbt').copy_to test_cbt
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
