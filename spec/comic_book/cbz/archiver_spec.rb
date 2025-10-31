require 'spec_helper'

RSpec.describe ComicBook::CBZ::Archiver do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:source_folder) { File.join temp_dir, 'simple' }

    before do
      load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
      load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
      load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
    end

    it 'stores absolute path of source folder' do
      archiver = described_class.new source_folder
      expect(archiver.send(:source_folder)).to eq File.expand_path(source_folder)
    end
  end

  describe '#archive' do
    context 'with simple fixture' do
      let(:source_folder) { File.join temp_dir, 'simple' }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
        load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
      end

      it 'creates a CBZ file with default extension' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        expect(File.extname(output_path)).to eq '.cbz'
        expect(File.basename(output_path, '.cbz')).to eq 'simple'
      end

      it 'creates archive with correct file structure' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        # Check that archive contains expected files without directory prefix
        created_entries = []
        Zip::File.open(output_path) do |zipfile|
          created_entries = zipfile.map(&:name).sort
        end

        expect(created_entries).to eq ['page1.jpg', 'page2.png', 'page3.gif']
      end

      it 'creates archive with custom extension' do
        archiver = described_class.new source_folder
        output_path = archiver.archive extension: :zip

        expect(File).to exist output_path
        expect(File.extname(output_path)).to eq '.zip'
      end

      it 'includes all image files in the archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        Zip::File.open(output_path) do |zipfile|
          entries = zipfile.map(&:name)
          expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
          expect(entries.length).to eq 3
        end
      end

      it 'preserves file contents in the archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        Zip::File.open(output_path) do |zipfile|
          page1_entry = zipfile.find_entry('page1.jpg')
          original_content = File.read(load_fixture('originals/simple/page1.jpg').path, mode: 'rb')
          expect(page1_entry.get_input_stream.read).to eq original_content
        end
      end

      it 'deletes original folder when delete_original is true' do
        archiver = described_class.new source_folder
        archiver.archive delete_original: true

        expect(File).not_to exist source_folder
      end

      it 'preserves original folder when delete_original is false' do
        archiver = described_class.new source_folder
        archiver.archive delete_original: false

        expect(File).to exist source_folder
      end

      it 'returns the path to the created archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(output_path).to be_a String
        expect(File).to exist output_path
        expect(File.dirname(output_path)).to eq File.dirname(source_folder)
      end
    end

    context 'with nested fixture' do
      let(:source_folder) { File.join temp_dir, 'nested' }

      before do
        load_fixture('originals/nested/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/nested/subfolder/nested.jpg').copy_to File.join(source_folder, 'subfolder', 'nested.jpg')
      end

      it 'creates archive with nested structure' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        created_entries = []
        Zip::File.open(output_path) do |zipfile|
          created_entries = zipfile.map(&:name).sort
        end

        expect(created_entries).to eq ['page1.jpg', 'subfolder/nested.jpg']
      end

      it 'includes nested files' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        Zip::File.open(output_path) do |zipfile|
          entries = zipfile.map(&:name)
          expect(entries).to include('subfolder/nested.jpg')
        end
      end
    end

    context 'with mixed fixture' do
      let(:source_folder) { File.join temp_dir, 'mixed' }

      before do
        load_fixture('originals/mixed/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/mixed/readme.txt').copy_to File.join(source_folder, 'readme.txt')
        load_fixture('originals/mixed/data.json').copy_to File.join(source_folder, 'data.json')
      end

      it 'creates archive with only image files' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        created_entries = []
        Zip::File.open(output_path) do |zipfile|
          created_entries = zipfile.map(&:name).sort
        end

        expect(created_entries).to eq ['page1.jpg']
      end

      it 'only includes image files' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        Zip::File.open(output_path) do |zipfile|
          entries = zipfile.map(&:name)
          expect(entries).to include('page1.jpg')
          expect(entries).not_to include('readme.txt', 'data.json')
        end
      end
    end

    context 'with empty fixture' do
      let(:source_folder) { File.join temp_dir, 'empty' }

      before do
        Dir.mkdir source_folder
      end

      it 'creates empty archive from empty folder' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        Zip::File.open(output_path) do |zipfile|
          expect(zipfile.entries).to be_empty
        end
      end
    end

    context 'with text_only fixture' do
      let(:source_folder) { File.join temp_dir, 'text_only' }

      before do
        load_fixture('originals/text_only/readme.txt').copy_to File.join(source_folder, 'readme.txt')
        load_fixture('originals/text_only/config.json').copy_to File.join(source_folder, 'config.json')
      end

      it 'creates empty archive from text-only folder' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        Zip::File.open(output_path) do |zipfile|
          expect(zipfile.entries).to be_empty
        end
      end
    end
  end
end
