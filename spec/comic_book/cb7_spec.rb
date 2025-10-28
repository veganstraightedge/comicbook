require 'spec_helper'

RSpec.describe ComicBook::CB7 do
  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'cb7') }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(simple_cb7) }

    let(:simple_cb7) { load_fixture('cb7/simple.cb7' }

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(simple_cb7)
    end
  end

  describe '#archive' do
    let(:source_folder) { load_fixture('cb7/simple.cb7' }
    let(:adapter) { described_class.new(source_folder) }

    it 'creates a CB7 file from source folder' do
      output_path = adapter.archive(source_folder)

      expect(File.exist?(output_path)).to be true
      expect(File.extname(output_path)).to eq '.cb7'
    end

    it 'includes image files in the archive' do
      output_path = adapter.archive(source_folder)

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          entries = szr.entries.map(&:path)
          expect(entries).to include('page1.jpg', 'page2.png')
        end
      end
    end

    it 'deletes original folder when delete_original is true' do
      adapter.archive(source_folder, delete_original: true)

      expect(File.exist?(source_folder)).to be false
    end

    it 'preserves original folder when delete_original is false' do
      adapter.archive(source_folder, delete_original: false)

      expect(File.exist?(source_folder)).to be true
    end

    it 'uses custom extension when specified' do
      output_path = adapter.archive(source_folder, extension: :'7z')

      expect(File.extname(output_path)).to eq '.cb7'
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(simple_cb7) }

    let(:simple_cb7) { load_fixture('cb7/simple.cb7' }

    it 'extracts CB7 file to folder' do
      extracted_path = adapter.extract

      expect(File.exist?(extracted_path)).to be true
      expect(File.directory?(extracted_path)).to be true
    end

    it 'uses .cb extension by default' do
      extracted_path = adapter.extract

      expect(File.extname(extracted_path)).to eq '.cb'
    end

    it 'uses custom extension when specified' do
      extracted_path = adapter.extract(extension: :comicbook)

      expect(File.extname(extracted_path)).to eq '.comicbook'
    end

    it 'uses no extension when extension is nil' do
      extracted_path = adapter.extract(extension: nil)

      expect(File.extname(extracted_path)).to eq ''
    end

    it 'extracts to custom destination when specified' do
      custom_destination = File.join(temp_dir, 'custom')
      extracted_path = adapter.extract(custom_destination)

      expect(extracted_path).to eq custom_destination
    end

    it 'deletes original file when delete_original is true' do
      adapter.extract(delete_original: true)

      expect(File.exist?(test_cb7)).to be false
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract(delete_original: false)

      expect(File.exist?(test_cb7)).to be true
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new(simple_cb7) }

    let(:simple_cb7) { load_fixture('cb7/simple.cb7') }

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

      let(:mixed_cb7) { load_fixture('cb7/mixed.cb7') }

      it 'only includes image files' do
        pages = adapter.pages

        expect(pages.length).to eq 1
        expect(pages.first.name).to eq 'page1.jpg'
      end
    end
  end
end
