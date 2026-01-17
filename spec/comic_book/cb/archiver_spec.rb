require 'spec_helper'

RSpec.describe ComicBook::CB::Archiver do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe '#initialize' do
    let(:source_folder) { File.join temp_dir, 'simple' }

    before do
      FileUtils.mkdir_p source_folder
    end

    it 'stores absolute path of source' do
      archiver = described_class.new source_folder
      expect(archiver.send(:source_path)).to eq File.expand_path(source_folder)
    end
  end

  describe '#archive' do
    context 'with a folder' do
      let(:source_folder) { File.join temp_dir, 'simple' }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/simple/page2.png').copy_to File.join(source_folder, 'page2.png')
        load_fixture('originals/simple/page3.gif').copy_to File.join(source_folder, 'page3.gif')
      end

      it 'renames folder to .cb extension' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist output_path
        expect(File).to be_directory output_path
        expect(File.extname(output_path)).to eq '.cb'
        expect(File.basename(output_path, '.cb')).to eq 'simple'
      end

      it 'moves folder in place (original no longer exists)' do
        archiver = described_class.new source_folder
        archiver.archive

        expect(File).not_to exist source_folder
      end

      it 'preserves all files in the folder' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        files = Dir.glob(File.join(output_path, '*')).map { File.basename it }
        expect(files.sort).to eq %w[page1.jpg page2.png page3.gif]
      end

      it 'returns the path to the created .cb folder' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(output_path).to be_a String
        expect(File).to exist output_path
        expect(output_path).to eq File.join(temp_dir, 'simple.cb')
      end

      it 'uses custom path when to: option provided' do
        archiver = described_class.new source_folder
        custom_path = File.join temp_dir, 'custom_name.cb'
        output_path = archiver.archive to: custom_path

        expect(output_path).to eq custom_path
        expect(File).to exist custom_path
        expect(File).to be_directory custom_path
      end

      it 'raises error when destination already exists' do
        archiver = described_class.new source_folder
        existing_path = File.join temp_dir, 'simple.cb'
        FileUtils.mkdir_p existing_path

        expect { archiver.archive }.to raise_error(ComicBook::Error, /already exists/)
      end
    end

    context 'with a single file' do
      let(:source_file) { File.join temp_dir, 'page1.jpg' }

      before do
        load_fixture('originals/simple/page1.jpg').copy_to source_file
      end

      it 'creates a .cb folder containing the file' do
        archiver = described_class.new source_file
        output_path = archiver.archive

        expect(File).to exist output_path
        expect(File).to be_directory output_path
        expect(File.extname(output_path)).to eq '.cb'
      end

      it 'names folder after the file basename' do
        archiver = described_class.new source_file
        output_path = archiver.archive

        expect(File.basename(output_path, '.cb')).to eq 'page1'
      end

      it 'moves the file into the new folder' do
        archiver = described_class.new source_file
        output_path = archiver.archive

        expect(File).not_to exist source_file
        expect(File).to exist File.join(output_path, 'page1.jpg')
      end

      it 'preserves file contents' do
        original_content = File.read source_file, mode: 'rb'
        archiver = described_class.new source_file
        output_path = archiver.archive

        moved_file = File.join output_path, 'page1.jpg'
        expect(File.read(moved_file, mode: 'rb')).to eq original_content
      end

      it 'uses custom path when to: option provided' do
        archiver = described_class.new source_file
        custom_path = File.join temp_dir, 'my_comic.cb'
        output_path = archiver.archive to: custom_path

        expect(output_path).to eq custom_path
        expect(File).to exist File.join(custom_path, 'page1.jpg')
      end

      it 'raises error when destination already exists' do
        archiver = described_class.new source_file
        existing_path = File.join temp_dir, 'page1.cb'
        FileUtils.mkdir_p existing_path

        expect { archiver.archive }.to raise_error(ComicBook::Error, /already exists/)
      end
    end

    context 'with nested folder' do
      let(:source_folder) { File.join temp_dir, 'nested' }

      before do
        load_fixture('originals/nested/page1.jpg').copy_to File.join(source_folder, 'page1.jpg')
        load_fixture('originals/nested/subfolder/nested.jpg').copy_to File.join(source_folder, 'subfolder', 'nested.jpg')
      end

      it 'preserves nested structure' do
        archiver = described_class.new source_folder
        output_path = archiver.archive

        expect(File).to exist File.join(output_path, 'page1.jpg')
        expect(File).to exist File.join(output_path, 'subfolder', 'nested.jpg')
      end
    end
  end
end
