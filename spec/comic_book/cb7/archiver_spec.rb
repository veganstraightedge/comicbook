require 'spec_helper'

RSpec.describe ComicBook::CB7::Archiver do
  subject(:archiver) { described_class.new(source_folder) }

  let(:temp_dir) { Dir.mktmpdir }
  let(:source_folder) { File.join(temp_dir, 'source') }

  before do
    Dir.mkdir(source_folder)
    File.write(File.join(source_folder, 'page1.jpg'), 'image1 content')
    File.write(File.join(source_folder, 'page2.png'), 'image2 content')
    File.write(File.join(source_folder, 'page3.gif'), 'image3 content')
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    it 'stores absolute path of source folder' do
      expect(archiver.send(:source_folder)).to eq File.expand_path(source_folder)
    end
  end

  describe '#archive' do
    it 'creates a CB7 file with default extension' do
      output_path = archiver.archive

      expect(File.exist?(output_path)).to be true
      expect(File.extname(output_path)).to eq '.cb7'
      expect(File.basename(output_path, '.cb7')).to eq 'source'
    end

    it 'creates archive with custom extension' do
      output_path = archiver.archive(extension: :cb7)

      expect(File.exist?(output_path)).to be true
      expect(File.extname(output_path)).to eq '.cb7'
    end

    it 'includes all image files in the archive' do
      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          entries = szr.entries.map(&:path)
          expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
          expect(entries.length).to eq 3
        end
      end
    end

    it 'preserves file contents in the archive' do
      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          page1_entry = szr.entries.find { |e| e.path == 'page1.jpg' }
          expect(szr.extract_data(page1_entry)).to eq 'image1 content'
        end
      end
    end

    it 'handles nested directories' do
      nested_dir = File.join(source_folder, 'subfolder')
      Dir.mkdir(nested_dir)
      File.write(File.join(nested_dir, 'nested.jpg'), 'nested content')

      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          entries = szr.entries.map(&:path)
          expect(entries).to include('subfolder/nested.jpg')
        end
      end
    end

    it 'ignores non-image files' do
      File.write(File.join(source_folder, 'readme.txt'), 'text content')
      File.write(File.join(source_folder, 'data.json'), '{}')

      output_path = archiver.archive

      File.open(output_path, 'rb') do |file|
        SevenZipRuby::Reader.open(file) do |szr|
          entries = szr.entries.map(&:path)
          expect(entries).not_to include('readme.txt', 'data.json')
          expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
        end
      end
    end

    it 'deletes original folder when delete_original is true' do
      archiver.archive(delete_original: true)

      expect(File.exist?(source_folder)).to be false
    end

    it 'preserves original folder when delete_original is false' do
      archiver.archive(delete_original: false)

      expect(File.exist?(source_folder)).to be true
    end

    it 'returns the path to the created archive' do
      output_path = archiver.archive

      expect(output_path).to be_a(String)
      expect(File.exist?(output_path)).to be true
      expect(File.dirname(output_path)).to eq File.dirname(source_folder)
    end

    context 'when source folder is empty' do
      subject(:archiver) { described_class.new(empty_folder) }

      let(:empty_folder) { File.join(temp_dir, 'empty') }

      before do
        Dir.mkdir(empty_folder)
      end

      it 'creates an empty archive' do
        output_path = archiver.archive

        expect(File.exist?(output_path)).to be true
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expect(szr.entries).to be_empty
          end
        end
      end
    end

    context 'when source folder has only non-image files' do
      subject(:archiver) { described_class.new(text_folder) }

      let(:text_folder) { File.join(temp_dir, 'text_only') }

      before do
        Dir.mkdir(text_folder)
        File.write(File.join(text_folder, 'readme.txt'), 'text')
        File.write(File.join(text_folder, 'config.json'), '{}')
      end

      it 'creates an empty archive' do
        output_path = archiver.archive

        expect(File.exist?(output_path)).to be true
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expect(szr.entries).to be_empty
          end
        end
      end
    end
  end
end
