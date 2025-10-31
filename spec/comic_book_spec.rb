require 'spec_helper'

RSpec.describe ComicBook do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  it 'has a version number' do
    expect(ComicBook::VERSION).not_to be_nil
  end

  describe '#new' do
    context 'with a file path' do
      subject(:cb) { described_class.new test_file }

      let(:test_file) { File.join temp_dir, 'simple.cbz' }
      let(:test_file_path) { File.expand_path test_file }

      before do
        load_fixture('cbz/simple.cbz').copy_to test_file
      end

      it 'creates a ComicBook instance with a file path' do
        expect(cb).to be_a described_class
        expect(cb.path).to eq test_file_path
        expect(cb.type).to eq :cbz
      end
    end

    context 'with a folder path' do
      subject(:cb) { described_class.new test_folder }

      let(:test_folder) { File.join temp_dir, 'test_folder' }
      let(:test_folder_path) { File.expand_path test_folder }

      before do
        Dir.mkdir test_folder
      end

      it 'creates a ComicBook instance with a folder path' do
        expect(cb).to be_a described_class
        expect(cb.path).to eq test_folder_path
        expect(cb.type).to eq :folder
      end
    end

    context 'with a non-existent path' do
      it 'raises an error' do
        expect { described_class.new '/non/existent/path' }.to raise_error ComicBook::Error, /Path does not exist/
      end
    end

    context 'with an unsupported file type' do
      let(:unsupported_file) { File.join temp_dir, 'test.txt' }

      before do
        File.write unsupported_file, 'content'
      end

      it 'raises an error' do
        expect { described_class.new unsupported_file }.to raise_error ComicBook::Error, /Unsupported file type/
      end
    end
  end

  describe '.load' do
    subject(:cb) { described_class.load test_file }

    let(:test_file) { File.join temp_dir, 'simple.cbz' }

    before do
      load_fixture('cbz/simple.cbz').copy_to test_file
    end

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
    let(:test_folder) { File.join temp_dir, 'test_folder.cb' }

    before do
      Dir.mkdir test_folder
    end

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
      let(:test_folder) { File.join temp_dir, 'simple' }
      let(:page_names) { pages.map(&:name) }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(test_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(test_folder, 'page2.png')
        load_fixture('originals/simple/page3.gif').copy_to File.join(test_folder, 'page3.gif')
      end

      it 'returns an array of Page objects' do
        expect(pages).to all(be_a(ComicBook::Page))
        expect(pages.length).to eq 3
      end

      it 'sorts pages alphabetically' do
        expect(page_names).to eq %w[page1.jpg page2.png page3.gif]
      end
    end

    context 'with an archive file' do
      subject(:pages) { cb.pages }

      let(:cb) { described_class.new test_file }
      let(:test_file) { File.join temp_dir, 'invalid.cbz' }

      before do
        File.write test_file, 'invalid zip content'
      end

      it 'raises error for invalid zip file' do
        expect { pages }.to raise_error(Zip::Error)
      end
    end
  end

  describe '#archive' do
    context 'with a folder' do
      subject(:cb) { described_class.new test_folder }

      let(:test_folder) { File.join temp_dir, 'simple' }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(test_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(test_folder, 'page2.png')
      end

      it 'creates a .cbz archive from folder' do
        archive_path = cb.archive test_folder

        expect(File).to exist archive_path
        expect(File.extname(archive_path)).to eq '.cbz'
      end

      it 'deletes original folder when delete_original is true' do
        cb.archive test_folder, delete_original: true

        expect(File).not_to exist test_folder
      end
    end

    context 'with an archive file' do
      subject(:cb) { described_class.new test_file }

      let(:test_file) { File.join temp_dir, 'simple.cbz' }
      let(:test_folder) { File.join temp_dir, 'dummy_folder' }

      before do
        load_fixture('cbz/simple.cbz').copy_to test_file
        Dir.mkdir test_folder
      end

      it 'raises error when trying to archive a file' do
        expect { cb.archive test_folder }.to raise_error(ComicBook::Error, 'Cannot archive a file')
      end
    end
  end

  describe '#extract' do
    context 'with a folder' do
      subject(:cb) { described_class.new test_folder }

      let(:test_folder) { File.join temp_dir, 'simple' }

      before do
        Dir.mkdir test_folder
      end

      it 'raises error when trying to extract a folder' do
        expect { cb.extract }.to raise_error(ComicBook::Error, 'Cannot extract a folder')
      end
    end

    context 'with an archive file' do
      subject(:cb) { described_class.new test_cbz }

      let(:extracted_folder_path) { cb.extract }
      let(:source_folder) { File.join temp_dir, 'source' }
      let(:test_cbz) do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')

        # Create a real CBZ file using our archive method
        folder_cb = described_class.new source_folder
        folder_cb.archive source_folder
      end

      it 'extracts archive to folder' do
        expect(File).to exist extracted_folder_path
        expect(File).to be_directory extracted_folder_path
      end

      context 'when delete_original is true' do
        before do
          cb.extract delete_original: true
        end

        it 'deletes original file' do
          expect(File).not_to exist test_cbz
        end
      end
    end
  end

  describe '.extract' do
    let(:source_folder) { File.join temp_dir, 'source' }
    let(:test_cbz) do
      load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')

      # Create a real CBZ file
      folder_cb = described_class.new source_folder
      folder_cb.archive source_folder
    end

    it 'is a shorthand for load().extract()' do
      extracted_folder_path = described_class.extract test_cbz

      expect(File).to exist extracted_folder_path
      expect(File).to be_directory extracted_folder_path
    end
  end
end
