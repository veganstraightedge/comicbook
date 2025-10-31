require 'spec_helper'

RSpec.describe ComicBook::CBT::Archiver do
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
      let(:expected_cbt) { load_fixture('cbt/simple.cbt').path }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
        load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
      end

      it 'creates a CBT file with default extension' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        expect(File.extname(output_path)).to eq '.cbt'
        expect(File.basename(output_path, '.cbt')).to eq 'simple'
      end

      it 'creates archive matching simple.cbt fixture' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        # Compare archive contents with fixture
        created_entries = []
        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            tar.each { created_entries << it.full_name if it.file? }
          end
        end

        expected_entries = []
        File.open(expected_cbt, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            tar.each { expected_entries << it.full_name if it.file? }
          end
        end

        expect(created_entries.sort).to eq expected_entries.sort
      end

      it 'creates archive with custom extension' do
        archiver = described_class.new source_folder
        output_path = archiver.archive extension: :comicbook

        expect(File.extname(output_path)).to eq '.comicbook'
      end

      it 'includes all image files in the archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            entries = tar.map { it.full_name if it.file? }.compact
            expect(entries).to include('page1.jpg', 'page2.png', 'page3.gif')
          end
        end
      end

      it 'preserves file contents in the archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            entry = tar.find { it.full_name == 'page1.jpg' }
            expected_content = File.binread(load_fixture('originals/simple/page1.jpg').path)
            expect(entry.read).to eq expected_content
          end
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
      end
    end

    context 'with nested fixture' do
      let(:source_folder) { File.join temp_dir, 'nested' }

      before do
        load_fixture('originals/nested/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/nested/subfolder/nested.jpg').copy_to File.join(source_folder, 'subfolder', 'nested.jpg')
      end

      it 'creates archive matching nested.cbt fixture' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            tar.each { created_entries << it.full_name if it.file? }
          end
        end

        expect(created_entries.sort).to include('page1.jpg', 'subfolder/nested.jpg')
      end

      it 'includes nested files' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            nested_entry = tar.find { it.full_name == 'subfolder/nested.jpg' }
            expect(nested_entry).not_to be_nil
          end
        end
      end
    end

    context 'with mixed fixture' do
      let(:source_folder) { File.join temp_dir, 'mixed' }

      before do
        load_fixture('originals/mixed/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/mixed/readme.txt').copy_to File.join(source_folder, 'readme.txt')
      end

      it 'creates archive matching mixed.cbt fixture' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            tar.each { created_entries << it.full_name if it.file? }
          end
        end

        expect(created_entries).to include('page1.jpg')
        expect(created_entries).not_to include('readme.txt')
      end

      it 'only includes image files' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            entries = tar.map { it.full_name if it.file? }.compact
            expect(entries).to include('page1.jpg')
            expect(entries).not_to include('readme.txt')
          end
        end
      end
    end

    context 'with empty fixture' do
      let(:source_folder) { File.join temp_dir, 'empty' }

      before do
        Dir.mkdir source_folder
      end

      it 'creates archive matching empty.cbt fixture' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            expect(tar.count).to eq 0
          end
        end
      end

      it 'creates an empty archive' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            expect(tar.to_a).to be_empty
          end
        end
      end
    end

    context 'with text_only fixture' do
      let(:source_folder) { File.join temp_dir, 'text_only' }

      before do
        load_fixture('originals/text_only/readme.txt').copy_to File.join(source_folder, 'readme.txt')
      end

      it 'creates archive matching text_only.cbt fixture' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            expect(tar.count).to eq 0
          end
        end
      end

      it 'creates an empty archive when only non-image files exist' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          Gem::Package::TarReader.new(file) do |tar|
            entries = tar.map { it.full_name if it.file? }.compact
            expect(entries).to be_empty
          end
        end
      end
    end
  end
end
