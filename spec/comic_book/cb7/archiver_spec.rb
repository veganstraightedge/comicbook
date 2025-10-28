require 'spec_helper'

RSpec.describe ComicBook::CB7::Archiver do
  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'cb7') }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '#initialize' do
    let(:source_folder) { File.join(temp_dir, 'simple') }

    before do
      FileUtils.cp_r(File.join(fixtures_dir, 'simple'), source_folder)
    end

    it 'stores absolute path of source folder' do
      archiver = described_class.new(source_folder)
      expect(archiver.send(:source_folder)).to eq File.expand_path(source_folder)
    end
  end

  describe '#archive' do
    context 'with simple fixture' do
      let(:source_folder) { File.join(temp_dir, 'simple') }
      let(:expected_cb7) { File.join(fixtures_dir, 'simple.cb7') }

      before do
        FileUtils.cp_r(File.join(fixtures_dir, 'simple'), source_folder)
      end

      it 'creates a CB7 file with default extension' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        expect(File.exist?(output_path)).to be true
        expect(File.extname(output_path)).to eq '.cb7'
        expect(File.basename(output_path, '.cb7')).to eq 'simple'
      end

      it 'creates archive matching simple.cb7 fixture' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        # Compare archive contents with fixture
        created_entries = []
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            created_entries = szr.entries.map(&:path).sort
          end
        end

        expected_entries = []
        File.open(expected_cb7, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expected_entries = szr.entries.map(&:path).sort
          end
        end

        expect(created_entries).to eq expected_entries
      end

      it 'creates archive with custom extension' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive(extension: :cb7)

        expect(File.exist?(output_path)).to be true
        expect(File.extname(output_path)).to eq '.cb7'
      end

      it 'includes all image files in the archive' do
        archiver = described_class.new(source_folder)
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
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            page1_entry = szr.entries.find { |e| e.path == 'page1.jpg' }
            expect(szr.extract_data(page1_entry)).not_to be_empty
          end
        end
      end

      it 'deletes original folder when delete_original is true' do
        archiver = described_class.new(source_folder)
        archiver.archive(delete_original: true)

        expect(File.exist?(source_folder)).to be false
      end

      it 'preserves original folder when delete_original is false' do
        archiver = described_class.new(source_folder)
        archiver.archive(delete_original: false)

        expect(File.exist?(source_folder)).to be true
      end

      it 'returns the path to the created archive' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        expect(output_path).to be_a(String)
        expect(File.exist?(output_path)).to be true
        expect(File.dirname(output_path)).to eq File.dirname(source_folder)
      end
    end

    context 'with nested fixture' do
      let(:source_folder) { File.join(temp_dir, 'nested') }
      let(:expected_cb7) { File.join(fixtures_dir, 'nested.cb7') }

      before do
        FileUtils.cp_r(File.join(fixtures_dir, 'nested'), source_folder)
      end

      it 'creates archive matching nested.cb7 fixture' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            created_entries = szr.entries.map(&:path).sort
          end
        end

        expected_entries = []
        File.open(expected_cb7, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expected_entries = szr.entries.map(&:path).sort
          end
        end

        expect(created_entries).to eq expected_entries
      end

      it 'includes nested files' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            entries = szr.entries.map(&:path)
            expect(entries).to include('subfolder/nested.jpg')
          end
        end
      end
    end

    context 'with mixed fixture' do
      let(:source_folder) { File.join(temp_dir, 'mixed') }
      let(:expected_cb7) { File.join(fixtures_dir, 'mixed.cb7') }

      before do
        FileUtils.cp_r(File.join(fixtures_dir, 'mixed'), source_folder)
      end

      it 'creates archive matching mixed.cb7 fixture' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            created_entries = szr.entries.map(&:path).sort
          end
        end

        expected_entries = []
        File.open(expected_cb7, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expected_entries = szr.entries.map(&:path).sort
          end
        end

        expect(created_entries).to eq expected_entries
      end

      it 'only includes image files' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            entries = szr.entries.map(&:path)
            expect(entries).not_to include('readme.txt', 'data.json')
            expect(entries).to include('page1.jpg')
          end
        end
      end
    end

    context 'with empty fixture' do
      let(:source_folder) { File.join(temp_dir, 'empty') }
      let(:expected_cb7) { File.join(fixtures_dir, 'empty.cb7') }

      before do
        FileUtils.cp_r(File.join(fixtures_dir, 'empty'), source_folder)
      end

      it 'creates archive matching empty.cb7 fixture' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            created_entries = szr.entries.map(&:path).sort
          end
        end

        expected_entries = []
        File.open(expected_cb7, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expected_entries = szr.entries.map(&:path).sort
          end
        end

        expect(created_entries).to eq expected_entries
      end

      it 'creates an empty archive' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        expect(File.exist?(output_path)).to be true
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expect(szr.entries).to be_empty
          end
        end
      end
    end

    context 'with text_only fixture' do
      let(:source_folder) { File.join(temp_dir, 'text_only') }
      let(:expected_cb7) { File.join(fixtures_dir, 'text_only.cb7') }

      before do
        FileUtils.cp_r(File.join(fixtures_dir, 'text_only'), source_folder)
      end

      it 'creates archive matching text_only.cb7 fixture' do
        archiver = described_class.new(source_folder)
        output_path = archiver.archive

        created_entries = []
        File.open(output_path, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            created_entries = szr.entries.map(&:path).sort
          end
        end

        expected_entries = []
        File.open(expected_cb7, 'rb') do |file|
          SevenZipRuby::Reader.open(file) do |szr|
            expected_entries = szr.entries.map(&:path).sort
          end
        end

        expect(created_entries).to eq expected_entries
      end

      it 'creates an empty archive when only non-image files exist' do
        archiver = described_class.new(source_folder)
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
