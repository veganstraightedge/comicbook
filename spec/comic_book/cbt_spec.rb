require 'spec_helper'

RSpec.describe ComicBook::CBT do
  subject(:adapter) { described_class.new test_cbt }

  let(:temp_dir) { Dir.mktmpdir }
  let(:source_folder) { File.join(temp_dir, 'source') }
  let(:test_cbt) { File.join(temp_dir, 'test.cbt') }

  before do
    Dir.mkdir(source_folder)
    File.write(File.join(source_folder, 'page1.jpg'), 'image1 content')
    File.write(File.join(source_folder, 'page2.png'), 'image2 content')
  end

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cbt)
    end
  end

  describe '#archive' do
    it 'creates a CBT file from source folder' do
      output_path = adapter.archive source_folder

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cbt'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive source_folder

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entries = tar.map(&:full_name)
          expect(entries).to include('page1.jpg', 'page2.png')
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
      output_path = adapter.archive source_folder, extension: :cbtx

      expect(File.extname(output_path)).to eq '.cbtx'
    end
  end

  describe '#extract' do
    subject(:extract_adapter) { described_class.new test_cbt }

    before do
      # Create a real CBT file first using the source folder
      source_adapter = described_class.new source_folder
      output_path = source_adapter.archive source_folder
      # Move the created archive to the expected location if needed
      File.rename(output_path, test_cbt) if output_path != test_cbt
    end

    it 'extracts CBT file to folder' do
      extraction_path = extract_adapter.extract

      expect(Dir).to exist extraction_path
      expect(File).to exist File.join(extraction_path, 'page1.jpg')
      expect(File).to exist File.join(extraction_path, 'page2.png')
    end

    it 'uses .cb extension by default' do
      extraction_path = extract_adapter.extract

      expect(File.basename(extraction_path)).to eq 'test.cb'
    end

    it 'uses custom extension when specified' do
      extraction_path = extract_adapter.extract nil, extension: '.custom'

      expect(File.basename(extraction_path)).to eq 'test.custom'
    end

    it 'uses no extension when extension is nil' do
      extraction_path = extract_adapter.extract nil, extension: nil

      expect(File.basename(extraction_path)).to eq 'test'
    end

    it 'extracts to custom destination when specified' do
      custom_dest = File.join(temp_dir, 'custom_extraction')
      extraction_path = extract_adapter.extract custom_dest

      expect(extraction_path).to eq custom_dest
      expect(Dir).to exist custom_dest
    end

    it 'deletes original file when delete_original is true' do
      extract_adapter.extract nil, delete_original: true
      expect(File).not_to exist test_cbt
    end

    it 'preserves original file when delete_original is false' do
      extract_adapter.extract nil, delete_original: false
      expect(File).to exist test_cbt
    end
  end

  describe '#pages' do
    subject(:pages_adapter) { described_class.new test_cbt }

    before do
      # Create a real CBT file first using the source folder
      source_adapter = described_class.new source_folder
      output_path = source_adapter.archive source_folder
      # Move the created archive to the expected location if needed
      File.rename(output_path, test_cbt) if output_path != test_cbt
    end

    it 'returns array of Page objects' do
      pages = pages_adapter.pages

      expect(pages).to be_an Array
      expect(pages.all? { |page| page.is_a? ComicBook::Page }).to be true
    end

    it 'sorts pages alphabetically by name' do
      pages = pages_adapter.pages
      names = pages.map(&:name)

      expect(names).to eq names.sort
    end

    it 'sets correct path and name for each page' do
      pages = pages_adapter.pages
      page = pages.first

      expect(page.path).to be_a String
      expect(page.name).to be_a String
    end

    context 'with non-image files in the archive' do
      before do
        File.write(File.join(source_folder, 'readme.txt'), 'not an image')
        mixed_adapter = described_class.new source_folder
        output_path = mixed_adapter.archive source_folder
        File.rename(output_path, test_cbt) if output_path != test_cbt
      end

      it 'only includes image files' do
        pages = pages_adapter.pages
        names = pages.map(&:name)

        expect(names).to include('page1.jpg', 'page2.png')
        expect(names).not_to include('readme.txt')
      end
    end
  end
end
