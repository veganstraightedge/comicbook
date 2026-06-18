require 'spec_helper'

RSpec.describe ComicBook::ArchiveContents do
  let(:temp_dir)      { Dir.mktmpdir }
  let(:source_folder) { File.join temp_dir, 'with_info' }

  before do
    load_fixture('originals/with_info/page1.jpg').copy_to     File.join(source_folder, 'page1.jpg')
    load_fixture('originals/with_info/ComicInfo.xml').copy_to File.join(source_folder, 'ComicInfo.xml')
    load_fixture('originals/with_info/MetronInfo.xml').copy_to File.join(source_folder, 'MetronInfo.xml')
    load_fixture('originals/with_info/notes.txt').copy_to File.join(source_folder, 'notes.txt')
  end

  after { FileUtils.rm_rf temp_dir }

  def basenames mode
    described_class.files(source_folder, mode).map { File.basename it }
  end

  describe '.files' do
    it 'includes every file with :all' do
      expect(basenames(:all)).to eq %w[ComicInfo.xml MetronInfo.xml notes.txt page1.jpg]
    end

    it 'includes only images with :images_only' do
      expect(basenames(:images_only)).to eq %w[page1.jpg]
    end

    it 'includes images plus ComicInfo.xml and MetronInfo.xml with :images_and_info' do
      expect(basenames(:images_and_info)).to eq %w[ComicInfo.xml MetronInfo.xml page1.jpg]
    end

    it 'raises on an unknown mode' do
      expect { described_class.files source_folder, :bogus }
        .to raise_error ComicBook::Error, /Unknown archive contents mode/
    end
  end
end
