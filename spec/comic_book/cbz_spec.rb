require 'spec_helper'

RSpec.describe ComicBook::CBZ do
  subject(:adapter) { described_class.new test_cbz }

  let(:temp_dir) { Dir.mktmpdir }
  let(:source_folder) { File.join(temp_dir, 'source') }
  let(:test_cbz) { File.join(temp_dir, 'test.cbz') }

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
      expect(adapter.send(:path)).to eq File.expand_path(test_cbz)
    end
  end

  describe '#archive' do
    it 'creates a CBZ file from source folder' do
      output_path = adapter.archive(source_folder)

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cbz'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive(source_folder)

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).to include('page1.jpg', 'page2.png')
      end
    end

    it 'deletes original folder when delete_original is true' do
      adapter.archive(source_folder, delete_original: true)
      expect(File).not_to exist(source_folder)
    end

    it 'preserves original folder when delete_original is false' do
      adapter.archive(source_folder, delete_original: false)
      expect(File).to exist source_folder
    end

    it 'uses custom extension when specified' do
      output_path = adapter.archive(source_folder, extension: :zip)
      expect(File.extname(output_path)).to eq '.zip'
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new cbz_file }

    let(:cbz_file) { File.join(temp_dir, 'extract_test.cbz') }

    before do
      # Create a real CBZ file first using the source folder
      source_adapter = described_class.new source_folder
      output_path = source_adapter.archive source_folder
      # Move the created archive to the expected location
      File.rename(output_path, cbz_file) if output_path != cbz_file
    end

    it 'extracts CBZ file to folder' do
      extract_path = adapter.extract

      expect(File).to exist extract_path
      expect(File).to be_directory extract_path

      expect(File).to exist File.join(extract_path, 'page1.jpg')
      expect(File).to exist File.join(extract_path, 'page2.png')
    end

    it 'uses .cb extension by default' do
      extract_path = adapter.extract
      expect(File.extname(extract_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extract_path = adapter.extract(nil, extension: :folder)
      expect(File.extname(extract_path)).to eq '.folder'
    end

    it 'uses no extension when extension is nil' do
      extract_path = adapter.extract(nil, extension: nil)
      expect(File.extname(extract_path)).to be_empty
    end

    it 'extracts to custom destination when specified' do
      custom_dest = File.join(temp_dir, 'custom_extract')
      extract_path = adapter.extract(custom_dest)

      expect(extract_path).to eq custom_dest
      expect(File).to exist custom_dest
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract(nil, delete_original: true)
      expect(File).not_to exist(cbz_file)
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract(nil, delete_original: false)
      expect(File).to exist cbz_file
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new cbz_file }

    let(:cbz_file) { File.join temp_dir, 'pages_test.cbz' }
    let(:pages) { adapter.pages }
    let(:page_names) { pages.map &:name }
    let(:page_one) { pages.find { |p| p.name == 'page1.jpg' } }
    let(:page_two) { pages.find { |p| p.name == 'page2.png' } }

    # Create a real CBZ file first using the source folder
    let(:source_adapter) { described_class.new source_folder }
    let(:output_path)    { source_adapter.archive source_folder }

    before do
      # Move the created archive to the expected location
      File.rename(output_path, cbz_file) if output_path != cbz_file
    end

    it 'returns array of Page objects' do
      expect(pages).to be_all ComicBook::Page
      expect(pages.length).to eq 2
    end

    it 'sorts pages alphabetically by name' do
      expect(page_names).to eq %w[page1.jpg page2.png]
    end

    it 'sets correct path and name for each page' do
      expect(page_one.path).to eq 'page1.jpg'
      expect(page_one.name).to eq 'page1.jpg'
      expect(page_two.path).to eq 'page2.png'
      expect(page_two.name).to eq 'page2.png'
    end

    context 'with non-image files in the archive' do
      before do
        # Add a non-image file to the source
        non_image_file = File.join source_folder, 'readme.txt'
        File.write non_image_file, 'text content'

        # Recreate the CBZ with the text file
        source_adapter = described_class.new source_folder
        FileUtils.rm_f cbz_file
        output_path = source_adapter.archive source_folder

        # Move the created archive to the expected location
        File.rename(output_path, cbz_file) if output_path != cbz_file
      end

      it 'only includes image files' do
        expect(page_names).to include 'page1.jpg', 'page2.png'
        expect(page_names).not_to include 'readme.txt'
      end
    end
  end
end
