require 'spec_helper'

RSpec.describe ComicBook::CB::Extractor do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:cb_folder) { File.join temp_dir, 'test.cb' }

    before do
      FileUtils.mkdir_p cb_folder
    end

    it 'stores absolute path of archive' do
      extractor = described_class.new cb_folder
      expect(extractor.send(:archive_path)).to eq File.expand_path(cb_folder)
    end
  end

  describe '#extract' do
    let(:cb_folder) { File.join temp_dir, 'test.cb' }

    before do
      FileUtils.mkdir_p cb_folder
      load_fixture('originals/simple/page1.jpg').copy_to File.join(cb_folder, 'page1.jpg')
    end

    it 'raises error explaining .cb folders are already extracted' do
      extractor = described_class.new cb_folder

      expect { extractor.extract }.to raise_error(
        ComicBook::Error,
        '.cb folders are already extracted (they are uncompressed folders)'
      )
    end
  end
end
