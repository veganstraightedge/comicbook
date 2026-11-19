require 'spec_helper'

# macOS adds members of its own to archives it makes: an AppleDouble `._name` beside a file that
# has extended attributes (tar), or the same data in a `__MACOSX` folder (Finder's Compress).
# They are not part of the comic.
RSpec.describe ComicBook do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf temp_dir
  end

  describe ComicBook::Entry do
    it 'recognizes AppleDouble members and the __MACOSX folder' do
      expect(described_class.new('._page1.jpg')).to             be_macos_metadata
      expect(described_class.new('sub/._page2.png')).to         be_macos_metadata
      expect(described_class.new('._sub/page2.png')).to         be_macos_metadata
      expect(described_class.new('__MACOSX/._page1.jpg')).to    be_macos_metadata
      expect(described_class.new('__MACOSX/sub/page2.png')).to  be_macos_metadata
      expect(described_class.new('comic/__MACOSX/page1.jpg')).to be_macos_metadata
    end

    it 'leaves ordinary files alone' do
      expect(described_class.new('page1.jpg')).not_to            be_macos_metadata
      expect(described_class.new('sub/page2.png')).not_to        be_macos_metadata
      expect(described_class.new('ComicInfo.xml')).not_to        be_macos_metadata
      expect(described_class.new('.hidden.jpg')).not_to          be_macos_metadata
      expect(described_class.new('page._1.jpg')).not_to          be_macos_metadata
      expect(described_class.new('MACOSX/page1.jpg')).not_to     be_macos_metadata
      expect(described_class.new('my__MACOSX/page1.jpg')).not_to be_macos_metadata
    end
  end

  %w[cbt cbz cb7].each do |format|
    describe "a .#{format} made on a Mac" do
      let(:archive) { File.join temp_dir, "macos_metadata.#{format}" }
      let(:comic)   { described_class.load archive }

      before do
        load_fixture("#{format}/macos_metadata.#{format}").copy_to archive
      end

      it 'lists only the real files' do
        expect(comic.files.map(&:path)).to eq %w[page1.jpg sub/page2.png]
      end

      it 'counts only the real pages' do
        expect(comic.pages.map(&:path)).to eq %w[page1.jpg sub/page2.png]
      end

      it 'extracts only the real files' do
        destination = comic.extract to: File.join(temp_dir, 'extracted.cb')
        everything  = Dir.glob '**/*', File::FNM_DOTMATCH, base: destination
        extracted   = everything.select { File.file? File.join(destination, it) }

        expect(extracted.sort).to eq %w[page1.jpg sub/page2.png]
      end
    end
  end

  describe 'a folder with a __MACOSX folder' do
    let(:folder) { File.join temp_dir, 'macos_metadata.cb' }
    let(:comic)  { described_class.load folder }

    before do
      FileUtils.cp_r File.join(__dir__, 'fixtures', 'cb', 'macos_metadata.cb'), folder
    end

    it 'counts only the real pages' do
      expect(comic.pages.map(&:path)).to eq %w[page1.jpg]
    end

    it 'leaves the folder out when archived' do
      archive = comic.archive to: File.join(temp_dir, 'archived.cbz')

      expect(described_class.load(archive).files.map(&:path)).to eq %w[page1.jpg]
      Zip::File.open(archive) do |zipfile|
        expect(zipfile.map(&:name)).to eq %w[page1.jpg]
      end
    end
  end
end
