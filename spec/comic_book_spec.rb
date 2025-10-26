require 'spec_helper'
require 'tmpdir'

RSpec.describe ComicBook do
  let(:temp_dir) { Dir.mktmpdir }
  let(:test_file) { File.join(temp_dir, 'test.cbz') }
  let(:test_folder) { File.join(temp_dir, 'test_folder') }

  before do
    File.write test_file, 'dummy content'
    Dir.mkdir test_folder
  end

  after do
    FileUtils.rm_rf temp_dir
  end

  it 'has a version number' do
    expect(ComicBook::VERSION).not_to be_nil
  end

  describe '#new' do
    it 'creates a ComicBook instance with a file path' do
      cb = described_class.new test_file
      test_file_path = File.expand_path(test_file)

      expect(cb).to be_a described_class
      expect(cb.path).to eq test_file_path
      expect(cb.type).to eq :cbz
    end

    it 'creates a ComicBook instance with a folder path' do
      cb = described_class.new test_folder
      test_folder_path = File.expand_path(test_folder)

      expect(cb).to be_a described_class
      expect(cb.path).to eq test_folder_path
      expect(cb.type).to eq :folder
    end

    it 'raises error for non-existent path' do
      expect { described_class.new('/non/existent/path') }.to raise_error ComicBook::Error, /Path does not exist/
    end

    it 'raises error for unsupported file type' do
      unsupported_file = File.join temp_dir, 'test.txt'
      File.write unsupported_file, 'content'

      expect { described_class.new(unsupported_file) }.to raise_error(ComicBook::Error, /Unsupported file type/)
    end
  end

  describe '.load' do
    it 'returns a ComicBook instance' do
      cb = described_class.load test_file

      expect(cb).to be_a described_class
      expect(cb.path).to eq File.expand_path(test_file)
    end

    it 'is equivalent to .new' do
      cb_new  = described_class.new  test_file
      cb_load = described_class.load test_file

      expect(cb_new.path).to eq cb_load.path
      expect(cb_new.type).to eq cb_load.type
    end
  end

  describe 'file type detection' do
    subject(:cb) { described_class.new file }

    let(:file) do
      temp_file = File.join temp_dir, "test#{file_ext}"
      File.write temp_file, 'content'
      temp_file
    end

    context 'when loading a .cbz' do
      let(:file_ext) { '.cbz' }

      it 'detects .cbz files' do
        expect(cb.type).to eq :cbz
      end
    end

    context 'when loading a .cb7' do
      let(:file_ext) { '.cb7' }

      it 'detects .cb7 files' do
        expect(cb.type).to eq :cb7
      end
    end

    context 'when loading a .cbt' do
      let(:file_ext) { '.cbt' }

      it 'detects .cbt files' do
        expect(cb.type).to eq :cbt
      end
    end

    context 'when loading a .cbr' do
      let(:file_ext) { '.cbr' }

      it 'detects .cbr files' do
        expect(cb.type).to eq :cbr
      end
    end

    context 'when loading a .cba' do
      let(:file_ext) { '.cba' }

      it 'detects .cba files' do
        expect(cb.type).to eq :cba
      end
    end
  end

  describe 'folder detection' do
    subject(:cb) { described_class.new test_folder }

    context 'when loading a .cb folder' do
      it 'detects folders' do
        expect(cb.type).to eq :folder
      end
    end
  end
end
