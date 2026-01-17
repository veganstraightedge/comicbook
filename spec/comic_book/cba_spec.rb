require 'spec_helper'

RSpec.describe ComicBook::CBA do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    subject(:adapter) { described_class.new(test_cba) }

    let(:test_cba) { File.join(temp_dir, 'test.cba') }

    before do
      FileUtils.touch test_cba
    end

    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path(test_cba)
    end
  end

  describe '#archive' do
    let(:source_folder) { File.join(temp_dir, 'source') }
    let(:adapter) { described_class.new source_folder }

    before do
      FileUtils.mkdir_p source_folder
    end

    it 'raises error because ACE is proprietary' do
      expect { adapter.archive }.to raise_error(ComicBook::Error, /ACE is proprietary/)
    end
  end

  describe '#extract' do
    subject(:adapter) { described_class.new(test_cba) }

    let(:test_cba) { File.join(temp_dir, 'test.cba') }

    before do
      FileUtils.touch test_cba
    end

    it 'raises error because extraction is not yet implemented' do
      expect { adapter.extract }.to raise_error(ComicBook::Error, /not yet implemented/)
    end
  end

  describe '#pages' do
    subject(:adapter) { described_class.new(test_cba) }

    let(:test_cba) { File.join(temp_dir, 'test.cba') }

    before do
      FileUtils.touch test_cba
    end

    it 'raises error because page listing is not yet implemented' do
      expect { adapter.pages }.to raise_error(ComicBook::Error, /not yet implemented/)
    end
  end
end
