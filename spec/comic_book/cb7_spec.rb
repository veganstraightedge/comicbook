require 'spec_helper'

RSpec.describe ComicBook::CB7 do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_cb7) }

    let(:test_cb7) { File.join(temp_dir, 'simple.cb7') }

    before do
      load_fixture('cb7/simple.cb7').copy_to(test_cb7)
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cb7)
    end
  end

  describe '#archive' do
    let(:source_folder) { File.join(temp_dir, 'source') }
    let(:adapter) { described_class.new source_folder }

    before do
      load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
      load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
      load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
    end

    it 'creates a CB7 file from source folder' do
      output_path = adapter.archive source_folder

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cb7'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive source_folder

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          entries = szr.entries.map(&:path)
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
      output_path = adapter.archive source_folder, extension: :cb7

      expect(File.extname(output_path)).to eq '.cb7'
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(test_cb7) }

    let(:test_cb7) { File.join(temp_dir, 'simple.cb7') }

    before do
      load_fixture('cb7/simple.cb7').copy_to(test_cb7)
    end

    it 'extracts CB7 file to folder' do
      extracted_path = adapter.extract

      expect(File).to exist extracted_path
      expect(File).to be_directory extracted_path
    end

    it 'uses .cb extension by default' do
      extracted_path = adapter.extract

      expect(File.extname(extracted_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extracted_path = adapter.extract nil, extension: :comicbook

      expect(File.extname(extracted_path)).to eq '.comicbook'
    end

    it 'uses no extension when extension is nil' do
      extracted_path = adapter.extract nil, extension: nil

      expect(File.extname(extracted_path)).to be_empty
    end

    it 'extracts to custom destination when specified' do
      custom_destination = File.join temp_dir, 'custom'
      extracted_path = adapter.extract custom_destination

      expect(extracted_path).to eq custom_destination
      expect(File).to exist custom_destination
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract nil, delete_original: true

      expect(File).not_to exist test_cb7
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract nil, delete_original: false

      expect(File).to exist test_cb7
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new(test_cb7) }

    let(:test_cb7) { File.join(temp_dir, 'simple.cb7') }

    before do
      load_fixture('cb7/simple.cb7').copy_to(test_cb7)
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

      expect(pages.first.path).to eq 'page1.jpg'
      expect(pages.first.name).to eq 'page1.jpg'
    end

    context 'with non-image files in the archive' do
      subject(:adapter) { described_class.new(mixed_cb7) }

      let(:mixed_cb7) { File.join(temp_dir, 'mixed.cb7') }

      before do
        load_fixture('cb7/mixed.cb7').copy_to(mixed_cb7)
      end

      it 'only includes image files' do
        pages = adapter.pages

        expect(pages.length).to eq 1
        expect(pages.first.name).to eq 'page1.jpg'
      end
    end
  end
end
