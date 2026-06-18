require 'spec_helper'

RSpec.describe ComicBook::CB do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(cb_folder) }

    let(:cb_folder) { File.join(temp_dir, 'test.cb') }

    before do
      FileUtils.mkdir_p cb_folder
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(cb_folder)
    end
  end

  describe '#archive' do
    context 'with a folder' do
      let(:source_folder) { File.join(temp_dir, 'source') }
      let(:adapter) { described_class.new source_folder }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
      end

      it 'creates a .cb folder from source folder' do
        output_path = adapter.archive

        expect(File).to exist output_path
        expect(File).to be_directory output_path
        expect(File.extname(output_path)).to eq '.cb'
      end

      it 'includes all files in the folder' do
        output_path = adapter.archive

        files = Dir.glob(File.join(output_path, '*')).map { File.basename it }
        expect(files.sort).to eq %w[page1.jpg page2.png]
      end

      it 'uses custom path when to: option specified' do
        custom_path = File.join temp_dir, 'custom.cb'
        output_path = adapter.archive to: custom_path

        expect(output_path).to eq custom_path
        expect(File).to exist custom_path
      end
    end

    context 'with a single file' do
      let(:source_file) { File.join(temp_dir, 'page1.jpg') }
      let(:adapter) { described_class.new source_file }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to source_file
      end

      it 'creates a .cb folder containing the file' do
        output_path = adapter.archive

        expect(File).to exist output_path
        expect(File).to be_directory output_path
        expect(File).to exist File.join(output_path, 'page1.jpg')
      end
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(cb_folder) }

    let(:cb_folder) { File.join(temp_dir, 'test.cb') }

    before do
      FileUtils.mkdir_p cb_folder
      load_fixture('originals/simple/page1.jpg').copy_to File.join(cb_folder, 'page1.jpg')
    end

    it 'raises error explaining .cb folders are already extracted' do
      expect { adapter.extract }.to raise_error(
        ComicBook::Error,
        '.cb folders are already extracted (they are uncompressed folders)'
      )
    end
  end

  describe '#info' do
    context 'with ComicInfo.xml in the folder' do
      subject(:adapter) { described_class.new test_cb }

      let(:test_cb) { File.join temp_dir, 'with_comicinfo.cb' }

      before do
        FileUtils.mkdir_p test_cb
        load_fixture('_design-files/cb_with_comicinfo_xml/ComicInfo.xml')
          .copy_to File.join(test_cb, 'ComicInfo.xml')
      end

      it 'returns a ComicInfo object' do
        expect(adapter.info).to be_a ComicBook::Info
      end

      it 'has correct title' do
        expect(adapter.info.title).to eq 'The Amazing Spider-Man'
      end
    end

    context 'without ComicInfo.xml in the folder' do
      subject(:adapter) { described_class.new test_cb }

      let(:test_cb) { File.join temp_dir, 'empty.cb' }

      before do
        FileUtils.mkdir_p test_cb
      end

      it 'returns nil' do
        expect(adapter.info).to be_nil
      end
    end
  end

  describe '#entries' do
    subject(:adapter) { described_class.new(cb_folder) }

    let(:cb_folder) { File.join(temp_dir, 'test.cb') }

    before do
      FileUtils.mkdir_p cb_folder
      load_fixture('originals/simple/page1.jpg').copy_to File.join(cb_folder, 'page1.jpg')
      load_fixture('originals/simple/page2.png').copy_to File.join(cb_folder, 'page2.png')
      load_fixture('originals/simple/page3.gif').copy_to File.join(cb_folder, 'page3.gif')
    end

    it 'returns Entry objects for every member' do
      entries = adapter.entries

      expect(entries).to be_all ComicBook::Entry
      expect(entries.map(&:name)).to contain_exactly 'page1.jpg', 'page2.png', 'page3.gif'
    end

    it 'sets the path relative to the folder' do
      entry = adapter.entries.find { it.name == 'page1.jpg' }

      expect(entry.path).to eq 'page1.jpg'
    end

    context 'with nested files' do
      before do
        load_fixture('originals/nested/subfolder/nested.jpg').copy_to File.join(cb_folder, 'subfolder', 'nested.jpg')
      end

      it 'includes nested files with relative paths' do
        nested = adapter.entries.find { it.name == 'nested.jpg' }

        expect(nested).not_to be_nil
        expect(nested.path).to eq 'subfolder/nested.jpg'
      end
    end

    context 'with non-image files in the folder' do
      before do
        load_fixture('originals/mixed/readme.txt').copy_to File.join(cb_folder, 'readme.txt')
      end

      it 'includes non-image files too' do
        names = adapter.entries.map(&:name)

        expect(names).to include('readme.txt')
        expect(names).to include('page1.jpg')
      end
    end
  end
end
