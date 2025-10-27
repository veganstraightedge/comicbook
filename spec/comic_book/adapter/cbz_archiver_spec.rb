require 'spec_helper'
require 'tmpdir'

RSpec.describe ComicBook::Adapter::CBZArchiver do
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
    it 'creates a CBZ file with default extension' do
      output_path = archiver.archive

      expect(File.exist?(output_path)).to be true
      expect(File.extname(output_path)).to eq '.cbz'
      expect(File.basename(output_path, '.cbz')).to eq 'source'
    end

    it 'creates archive with custom extension' do
      output_path = archiver.archive(extension: :zip)

      expect(File.exist?(output_path)).to be true
      expect(File.extname(output_path)).to eq '.zip'
    end

    it 'includes all image files in the archive' do
      output_path = archiver.archive

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
        expect(entries.length).to eq 3
      end
    end

    it 'preserves file contents in the archive' do
      output_path = archiver.archive

      Zip::File.open(output_path) do |zipfile|
        page1_entry = zipfile.find_entry('page1.jpg')
        expect(page1_entry.get_input_stream.read).to eq 'image1 content'
      end
    end

    it 'sorts files alphabetically in the archive' do
      # Add files in non-alphabetical order
      File.write(File.join(source_folder, 'zebra.jpg'), 'zebra content')
      File.write(File.join(source_folder, 'alpha.png'), 'alpha content')

      output_path = archiver.archive

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).to eq entries.sort
      end
    end

    it 'handles nested directories' do
      nested_dir = File.join(source_folder, 'subfolder')
      Dir.mkdir(nested_dir)
      File.write(File.join(nested_dir, 'nested.jpg'), 'nested content')

      output_path = archiver.archive

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).to include('subfolder/nested.jpg')
      end
    end

    it 'ignores non-image files' do
      File.write(File.join(source_folder, 'readme.txt'), 'text content')
      File.write(File.join(source_folder, 'data.json'), '{}')

      output_path = archiver.archive

      Zip::File.open(output_path) do |zipfile|
        entries = zipfile.map(&:name)
        expect(entries).not_to include('readme.txt', 'data.json')
        expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
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
        Zip::File.open(output_path) do |zipfile|
          expect(zipfile.entries).to be_empty
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
        Zip::File.open(output_path) do |zipfile|
          expect(zipfile.entries).to be_empty
        end
      end
    end
  end
end
