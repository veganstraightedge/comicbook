require 'spec_helper'

RSpec.describe ComicBook::CBT::Archiver do
  subject(:archiver) { described_class.new source_folder }

  let(:temp_dir) { Dir.mktmpdir }
  let(:source_folder) { File.join temp_dir, 'source' }

  before do
    Dir.mkdir source_folder
    File.write File.join(source_folder, 'page1.jpg'), 'image1 content'
    File.write File.join(source_folder, 'page2.png'), 'image2 content'
    File.write File.join(source_folder, 'page3.gif'), 'image3 content'
  end

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    it 'stores absolute path of source folder' do
      expect(archiver.send(:source_folder)).to eq File.expand_path(source_folder)
    end
  end

  describe '#archive' do
    it 'creates a CBT file with default extension' do
      output_path = archiver.archive

      expect(File).to exist output_path
      expect(File.extname(output_path)).to eq '.cbt'
    end

    it 'includes all image files in the archive' do
      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entries = tar.map(&:full_name)
          expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
        end
      end
    end

    it 'preserves file contents in the archive' do
      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entry = tar.find { |e| e.full_name == 'page1.jpg' }
          expect(entry.read).to eq 'image1 content'
        end
      end
    end

    it 'creates archive with custom destination' do
      custom_path = File.join temp_dir, 'custom.cbt'
      output_path = archiver.archive destination: custom_path

      expect(output_path).to eq custom_path
      expect(File).to exist custom_path
    end

    it 'ignores non-image files' do
      File.write File.join(source_folder, 'readme.txt'), 'not an image'
      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entries = tar.map(&:full_name)
          expect(entries).not_to include('readme.txt')
        end
      end
    end

    it 'handles nested directories' do
      nested_dir = File.join source_folder, 'chapter1'
      Dir.mkdir nested_dir
      File.write File.join(nested_dir, 'nested.jpg'), 'nested content'

      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        Gem::Package::TarReader.new(file) do |tar|
          entries = tar.map(&:full_name)
          expect(entries).to include('chapter1/nested.jpg')
        end
      end
    end

    it 'returns the path to the created archive' do
      output_path = archiver.archive

      expect(output_path).to be_a String
      expect(File).to exist output_path
    end

    context 'when source folder is empty' do
      before do
        FileUtils.rm_rf Dir.glob(File.join(source_folder, '*'))
      end

      it 'creates an empty archive' do
        output_path = archiver.archive

        expect(File).to exist output_path
        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            expect(tar.count).to eq 0
          end
        end
      end
    end
  end
end
