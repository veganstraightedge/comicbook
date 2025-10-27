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
    context 'with a file path' do
      subject(:cb) { described_class.new test_file }

      let(:test_file_path) { File.expand_path test_file }

      it 'creates a ComicBook instance with a file path' do
        expect(cb).to be_a described_class
        expect(cb.path).to eq test_file_path
        expect(cb.type).to eq :cbz
      end
    end

    context 'with a folder path' do
      subject(:cb) { described_class.new test_folder }

      let(:test_folder_path) { File.expand_path test_folder }

      it 'creates a ComicBook instance with a folder path' do
        expect(cb).to be_a described_class
        expect(cb.path).to eq test_folder_path
        expect(cb.type).to eq :folder
      end
    end

    context 'with a non-existent path' do
      it 'raises an error' do
        expect { described_class.new('/non/existent/path') }.to raise_error ComicBook::Error, /Path does not exist/
      end
    end

    context 'with an unsupported file type' do
      let(:unsupported_file) { File.join temp_dir, 'test.txt' }

      it 'raises an error' do
        File.write unsupported_file, 'content'

        expect { described_class.new(unsupported_file) }.to raise_error ComicBook::Error, /Unsupported file type/
      end
    end
  end

  describe '.load' do
    subject(:cb) { described_class.load test_file }

    it 'returns a ComicBook instance' do
      expect(cb).to be_a described_class
      expect(cb.path).to eq File.expand_path(test_file)
    end

    it 'is equivalent to .new' do
      cb_via_new = described_class.new test_file

      expect(cb_via_new.path).to eq cb.path
      expect(cb_via_new.type).to eq cb.type
    end
  end

  describe 'file type detection' do
    subject(:type) { cb.type }

    let(:cb) { described_class.new file }
    let(:file) do
      temp_file = File.join temp_dir, "test#{file_ext}"
      File.write temp_file, 'content'
      temp_file
    end

    context 'when loading a .cbz' do
      let(:file_ext) { '.cbz' }

      it 'detects .cbz files' do
        expect(type).to eq :cbz
      end
    end

    context 'when loading a .cb7' do
      let(:file_ext) { '.cb7' }

      it 'detects .cb7 files' do
        expect(type).to eq :cb7
      end
    end

    context 'when loading a .cbt' do
      let(:file_ext) { '.cbt' }

      it 'detects .cbt files' do
        expect(type).to eq :cbt
      end
    end

    context 'when loading a .cbr' do
      let(:file_ext) { '.cbr' }

      it 'detects .cbr files' do
        expect(type).to eq :cbr
      end
    end

    context 'when loading a .cba' do
      let(:file_ext) { '.cba' }

      it 'detects .cba files' do
        expect(type).to eq :cba
      end
    end
  end

  describe 'folder detection' do
    subject(:type) { cb.type }

    let(:cb) { described_class.new test_folder }

    context 'when loading a .cb folder' do
      it 'detects folders' do
        expect(type).to eq :folder
      end
    end
  end

  describe '#pages' do
    context 'with a folder' do
      subject(:pages) { cb.pages }

      let(:cb) { described_class.new test_folder }
      let(:page_names) { pages.map &:name }

      before do
        %w[page1.jpg page2.png page3.gif].map do |filename|
          file_path = File.join(test_folder, filename)
          File.write(file_path, 'image content')
          file_path
        end
      end

      it 'returns an array of Page objects' do
        expect(pages).to be_all ComicBook::Page
        expect(pages.length).to eq 3
      end

      it 'sorts pages alphabetically' do
        expect(page_names).to eq %w[page1.jpg page2.png page3.gif]
      end
    end

    context 'with an archive file' do
      subject(:pages) { cb.pages }

      let(:cb) { described_class.new test_file }

      it 'raises error for invalid zip file' do
        expect { pages }.to raise_error(Zip::Error)
      end
    end
  end

  describe '#archive' do
    context 'with a folder' do
      subject(:cb) { described_class.new test_folder }

      before do
        %w[page1.jpg page2.png].map do |filename|
          file_path = File.join(test_folder, filename)
          File.write(file_path, 'image content')
          file_path
        end
      end

      it 'creates a .cbz archive from folder' do
        archive_path = cb.archive(test_folder)
        expect(File.exist?(archive_path)).to be true
        expect(File.extname(archive_path)).to eq '.cbz'
      end

      it 'deletes original folder when delete_original is true' do
        cb.archive(test_folder, delete_original: true)
        expect(File.exist?(test_folder)).to be false
      end
    end

    context 'with an archive file' do
      subject(:cb) { described_class.new test_file }

      it 'raises error when trying to archive a file' do
        expect { cb.archive(test_folder) }.to raise_error(ComicBook::Error, 'Cannot archive a file')
      end
    end
  end

  describe '#extract' do
    context 'with a folder' do
      subject(:cb) { described_class.new test_folder }

      it 'raises error when trying to extract a folder' do
        expect { cb.extract }.to raise_error(ComicBook::Error, 'Cannot extract a folder')
      end
    end

    context 'with an archive file' do
      subject(:cb) { described_class.new test_cbz }

      let(:source_folder) { File.join(temp_dir, 'source') }
      let(:test_cbz) do
        Dir.mkdir source_folder
        File.write File.join(source_folder, 'page1.jpg'), 'image1'
        File.write File.join(source_folder, 'page2.png'), 'image2'

        # Create a real CBZ file using our archive method
        folder_cb = described_class.new(source_folder)
        folder_cb.archive(source_folder)
      end

      it 'extracts archive to folder' do
        extract_path = cb.extract

        expect(File.exist?(extract_path)).to be true
        expect(File.directory?(extract_path)).to be true
      end

      it 'deletes original file when delete_original is true' do
        cb.extract delete_original: true

        expect(File.exist?(test_cbz)).to be false
      end
    end
  end

  describe '.extract' do
    let(:source_folder) { File.join temp_dir, 'source' }
    let(:test_cbz) do
      Dir.mkdir(source_folder)
      File.write(File.join(source_folder, 'page1.jpg'), 'image1')

      # Create a real CBZ file
      folder_cb = described_class.new(source_folder)
      folder_cb.archive(source_folder)
    end

    it 'is a shorthand for load().extract()' do
      extract_path = described_class.extract test_cbz

      expect(File.exist?(extract_path)).to be true
      expect(File.directory?(extract_path)).to be true
    end
  end
end
