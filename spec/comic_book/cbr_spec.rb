require 'spec_helper'

RSpec.describe ComicBook::CBR do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_cbr) }

    let(:test_cbr) { File.join(temp_dir, 'simple.cbr') }

    before do
      load_fixture('cbr/simple.cbr').copy_to(test_cbr)
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cbr)
    end
  end

  describe '#archive' do
    let(:source_folder) { File.join(temp_dir, 'source') }
    let(:adapter) { described_class.new source_folder }

    before do
      load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
    end

    it 'raises error because RAR is proprietary' do
      expect { adapter.archive }.to raise_error(ComicBook::Error, /not supported/)
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(test_cbr) }

    let(:test_cbr) { File.join(temp_dir, 'simple.cbr') }

    before do
      load_fixture('cbr/simple.cbr').copy_to(test_cbr)
    end

    it 'extracts CBR file to folder' do
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

      expect(File).not_to exist test_cbr
    end

    it 'preserves original file when delete_original is false' do
      adapter.extract delete_original: false

      expect(File).to exist test_cbr
    end
  end

  describe '#info' do
    context 'with ComicInfo.xml in the archive' do
      subject(:adapter) { described_class.new test_cbr }

      let(:test_cbr) { File.join temp_dir, 'with_comicinfo.cbr' }

      before do
        load_fixture('cbr/with_comicinfo.cbr').copy_to test_cbr
      end

      it 'returns a ComicInfo object' do
        expect(adapter.info).to be_a ComicBook::Info
      end

      it 'has correct title' do
        expect(adapter.info.title).to eq 'The Amazing Spider-Man'
      end
    end

    context 'without ComicInfo.xml in the archive' do
      subject(:adapter) { described_class.new test_cbr }

      let(:test_cbr) { File.join temp_dir, 'simple.cbr' }

      before do
        load_fixture('cbr/simple.cbr').copy_to test_cbr
      end

      it 'returns nil' do
        expect(adapter.info).to be_nil
      end
    end
  end

  describe '#entries' do
    subject(:adapter) { described_class.new(test_cbr) }

    let(:test_cbr) { File.join(temp_dir, 'simple.cbr') }

    before do
      load_fixture('cbr/simple.cbr').copy_to(test_cbr)
    end

    it 'returns Entry objects for every member' do
      entries = adapter.entries

      expect(entries).to be_all ComicBook::Entry
      expect(entries.map(&:name)).to contain_exactly 'page1.jpg', 'page2.png', 'page3.gif'
    end

    it 'sets the path to the archive entry name' do
      entry = adapter.entries.find { it.name == 'page1.jpg' }

      expect(entry.path).to eq 'page1.jpg'
    end

    context 'with non-image files in the archive' do
      subject(:adapter) { described_class.new(mixed_cbr) }

      let(:mixed_cbr) { File.join(temp_dir, 'mixed.cbr') }

      before do
        load_fixture('cbr/mixed.cbr').copy_to(mixed_cbr)
      end

      it 'includes non-image files too' do
        names = adapter.entries.map(&:name)

        expect(names).to include('page1.jpg')
        expect(names).to include('readme.txt')
      end
    end
  end
end
