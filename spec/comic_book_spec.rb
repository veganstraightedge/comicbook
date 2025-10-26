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
    FileUtils.rm_rf(temp_dir)
  end

  it 'has a version number' do
    expect(ComicBook::VERSION).not_to be_nil
  end

  describe '.new' do
    it 'creates a ComicBook instance with a file path' do
      cb = described_class.new test_file

      expect(cb).to be_a described_class
      expect(cb.path).to eq File.expand_path(test_file)
      expect(cb.type).to eq :cbz
    end

    it 'creates a ComicBook instance with a folder path' do
      cb = described_class.new test_folder

      expect(cb).to be_a described_class
      expect(cb.path).to eq File.expand_path test_folder
      expect(cb.type).to eq :folder
    end

    it 'raises error for non-existent path' do
      expect { described_class.new('/non/existent/path') }.to raise_error(ComicBook::Error, /Path does not exist/)
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
    %w[.cbz .cb7 .cbt .cbr .cba].each do |ext|
      it "detects #{ext} files" do
        file = File.join(temp_dir, "test#{ext}")
        File.write(file, 'content')

        cb = described_class.new(file)

        expected_type = ext == '.cb7' ? :cb_seven : ext[1..].to_sym
        expect(cb.type).to eq(expected_type)
      end
    end

    it 'detects folders' do
      cb = described_class.new test_folder

      expect(cb.type).to eq :folder
    end
  end
end
