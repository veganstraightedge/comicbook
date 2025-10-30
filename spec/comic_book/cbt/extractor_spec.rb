require 'spec_helper'

RSpec.describe ComicBook::CBT::Extractor do
  subject(:extractor) { described_class.new test_cbt }

  let(:temp_dir) { Dir.mktmpdir }
  let(:source_folder) { File.join temp_dir, 'source' }
  let(:test_cbt) { File.join temp_dir, 'test.cbt' }

  before do
    Dir.mkdir source_folder
    File.write File.join(source_folder, 'page1.jpg'), 'image1 content'
    File.write File.join(source_folder, 'page2.png'), 'image2 content'
    File.write File.join(source_folder, 'page3.gif'), 'image3 content'

    # Create test CBT file
    File.open(test_cbt, 'wb') do |file|
      Gem::Package::TarWriter.new(file) do |tar|
        Dir.glob(File.join(source_folder, '*')).each do |file_path|
          next unless File.file?(file_path)

          stat = File.stat(file_path)
          tar.add_file(File.basename(file_path), stat.mode) do |io|
            File.open(file_path, 'rb') { |f| io.write(f.read) }
          end
        end
      end
    end
  end

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    it 'stores absolute path of archive file' do
      expect(extractor.send(:path)).to eq File.expand_path(test_cbt)
    end
  end

  describe '#extract' do
    it 'extracts CBT file to folder' do
      extraction_path = extractor.extract

      expect(Dir).to exist extraction_path
      expect(File).to exist File.join(extraction_path, 'page1.jpg')
      expect(File).to exist File.join(extraction_path, 'page2.png')
      expect(File).to exist File.join(extraction_path, 'page3.gif')
    end

    it 'uses default destination when none provided' do
      extraction_path = extractor.extract

      expected_path = File.join(temp_dir, 'test.cb')
      expect(extraction_path).to eq expected_path
    end

    it 'extracts to custom destination folder' do
      custom_dest = File.join temp_dir, 'custom_extraction'
      extraction_path = extractor.extract custom_dest

      expect(extraction_path).to eq custom_dest
      expect(Dir).to exist custom_dest
      expect(File).to exist File.join(custom_dest, 'page1.jpg')
    end

    it 'preserves file contents during extraction' do
      extraction_path = extractor.extract

      content = File.read File.join(extraction_path, 'page1.jpg')
      expect(content).to eq 'image1 content'
    end

    it 'handles nested directories' do
      # Create CBT with nested structure
      nested_cbt = File.join temp_dir, 'nested.cbt'
      File.open(nested_cbt, 'wb') do |file|
        Gem::Package::TarWriter.new(file) do |tar|
          tar.add_file('chapter1/page1.jpg', 0o644) { |io| io.write('nested content') }
        end
      end

      nested_extractor = described_class.new nested_cbt
      extraction_path = nested_extractor.extract

      expect(File).to exist File.join(extraction_path, 'chapter1', 'page1.jpg')
      expect(File.read(File.join(extraction_path, 'chapter1', 'page1.jpg'))).to eq 'nested content'
    end

    it 'ignores non-image files by default' do
      # Create CBT with mixed content
      mixed_cbt = File.join temp_dir, 'mixed.cbt'
      File.open(mixed_cbt, 'wb') do |file|
        Gem::Package::TarWriter.new(file) do |tar|
          tar.add_file('page1.jpg', 0o644) { |io| io.write('image content') }
          tar.add_file('readme.txt', 0o644) { |io| io.write('text content') }
        end
      end

      mixed_extractor = described_class.new mixed_cbt
      extraction_path = mixed_extractor.extract

      expect(File).to exist File.join(extraction_path, 'page1.jpg')
      expect(File).not_to exist File.join(extraction_path, 'readme.txt')
    end

    it 'extracts all files when all option is true' do
      # Create CBT with mixed content
      mixed_cbt = File.join temp_dir, 'mixed.cbt'
      File.open(mixed_cbt, 'wb') do |file|
        Gem::Package::TarWriter.new(file) do |tar|
          tar.add_file('page1.jpg', 0o644) { |io| io.write('image content') }
          tar.add_file('readme.txt', 0o644) { |io| io.write('text content') }
        end
      end

      mixed_extractor = described_class.new mixed_cbt
      extraction_path = mixed_extractor.extract nil, all: true

      expect(File).to exist File.join(extraction_path, 'page1.jpg')
      expect(File).to exist File.join(extraction_path, 'readme.txt')
    end

    it 'returns the path to the extracted folder' do
      extraction_path = extractor.extract

      expect(extraction_path).to be_a String
      expect(Dir).to exist extraction_path
    end

    context 'when archive is empty' do
      before do
        File.open(test_cbt, 'wb') do |file|
          Gem::Package::TarWriter.new(file) { |tar| }
        end
      end

      it 'creates empty extraction folder' do
        extraction_path = extractor.extract

        expect(Dir).to exist extraction_path
        expect(Dir.children(extraction_path)).to be_empty
      end
    end

    context 'when archive contains only non-image files' do
      before do
        File.open(test_cbt, 'wb') do |file|
          Gem::Package::TarWriter.new(file) do |tar|
            tar.add_file('readme.txt', 0o644) { |io| io.write('text content') }
          end
        end
      end

      it 'creates empty extraction folder' do
        extraction_path = extractor.extract

        expect(Dir).to exist extraction_path
        expect(Dir.children(extraction_path)).to be_empty
      end
    end

    context 'when destination folder already exists' do
      it 'extracts into existing folder' do
        existing_folder = File.join temp_dir, 'existing'
        Dir.mkdir existing_folder

        extraction_path = extractor.extract existing_folder

        expect(extraction_path).to eq existing_folder
        expect(File).to exist File.join(existing_folder, 'page1.jpg')
      end
    end
  end
end
