require 'spec_helper'

RSpec.describe ComicBook do
  let(:temp_dir) { Dir.mktmpdir }
  let(:folder)   { File.join temp_dir, 'comic' }
  let(:comic)    { described_class.load folder }

  # The three fixture pages, each with different contents.
  let(:jpg) { 'originals/simple/page1.jpg' }
  let(:png) { 'originals/simple/page2.png' }
  let(:gif) { 'originals/simple/page3.gif' }

  after do
    FileUtils.rm_rf temp_dir
  end

  # Put fixture files in the comic's folder: { 'a.jpg' => jpg, 'sub/b.png' => png }
  def fill directory, files
    FileUtils.mkdir_p directory
    files.each { |name, fixture| load_fixture(fixture).copy_to File.join(directory, name) }
  end

  def contents_of fixture
    File.binread File.join(__dir__, 'fixtures', fixture)
  end

  def contents_at relative
    File.binread File.join(folder, relative)
  end

  describe '#arrange_pages' do
    it 'reorders pages by renumbering them' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png, 'c.gif' => gif

      pages = comic.arrange_pages %w[c.gif a.jpg b.png]

      expect(pages.map(&:path)).to eq %w[page_001.gif page_002.jpg page_003.png]
      expect(contents_at('page_001.gif')).to eq contents_of(gif)
      expect(contents_at('page_002.jpg')).to eq contents_of(jpg)
      expect(contents_at('page_003.png')).to eq contents_of(png)
      expect(File).not_to exist File.join(folder, 'a.jpg')
    end

    it 'deletes pages left out' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png, 'c.gif' => gif

      pages = comic.arrange_pages %w[a.jpg c.gif]

      expect(pages.map(&:path)).to eq %w[page_001.jpg page_002.gif]
      expect(contents_at('page_002.gif')).to eq contents_of(gif)
      expect(described_class.load(folder).pages.length).to eq 2
    end

    it 'adds files given by absolute path from outside the folder' do
      fill folder, 'a.jpg' => jpg, 'b.gif' => gif
      elsewhere = File.join temp_dir, 'elsewhere'
      fill elsewhere, 'new.png' => png
      added = File.join elsewhere, 'new.png'

      pages = comic.arrange_pages ['a.jpg', added, 'b.gif']

      expect(pages.map(&:path)).to eq %w[page_001.jpg page_002.png page_003.gif]
      expect(contents_at('page_002.png')).to eq contents_of(png)
      # The outside file is copied, not moved.
      expect(File).to exist added
    end

    it 'treats absolute paths inside the folder as the existing pages' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      pages = comic.arrange_pages [File.join(folder, 'b.png'), File.join(folder, 'a.jpg')]

      expect(pages.map(&:path)).to eq %w[page_001.png page_002.jpg]
      expect(contents_at('page_001.png')).to eq contents_of(png)
    end

    it 'keeps pages in the subfolder they were in' do
      fill folder, 'simple/page1.jpg' => jpg, 'simple/page2.png' => png

      pages = comic.arrange_pages %w[simple/page2.png simple/page1.jpg]

      expect(pages.map(&:path)).to eq %w[simple/page_001.png simple/page_002.jpg]
      expect(contents_at('simple/page_001.png')).to eq contents_of(png)
    end

    it 'puts pages from different subfolders in their shared parent' do
      fill folder, 'book/one/a.jpg' => jpg, 'book/two/b.png' => png

      pages = comic.arrange_pages %w[book/two/b.png book/one/a.jpg]

      expect(pages.map(&:path)).to eq %w[book/page_001.png book/page_002.jpg]
    end

    it 'leaves other files alone' do
      fill folder, 'a.jpg'          => jpg,
                   'b.png'          => png,
                   'notes.txt'      => 'originals/with_info/notes.txt',
                   'MetronInfo.xml' => 'originals/with_info/MetronInfo.xml'

      comic.arrange_pages %w[b.png]

      expect(contents_at('notes.txt')).to eq contents_of('originals/with_info/notes.txt')
      expect(contents_at('MetronInfo.xml')).to eq contents_of('originals/with_info/MetronInfo.xml')
    end

    it 'brings the ComicInfo page entries in step with the pages' do
      FileUtils.cp_r File.join(__dir__, 'fixtures', 'originals', 'with_pages'), folder
      elsewhere = File.join temp_dir, 'elsewhere'
      fill elsewhere, 'new.jpg' => jpg

      # Back cover first, the story page deleted, a new page added at the end.
      comic.arrange_pages ['page3.gif', 'page1.jpg', File.join(elsewhere, 'new.jpg')]

      info = comic.info
      expect(info.title).to eq 'Chapter Seven'
      expect(info.page_count).to eq 3
      expect(info.pages.map(&:image)).to eq [0, 1, 2]
      expect(info.pages.map(&:type)).to eq %w[BackCover FrontCover Story]
      expect(info.pages.map(&:bookmark)).to eq ['', '', '']
    end

    it 'adds no ComicInfo to a folder without one' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      comic.arrange_pages %w[b.png a.jpg]

      expect(File).not_to exist File.join(folder, 'ComicInfo.xml')
    end

    it 'works on a .cb folder' do
      cb_folder = File.join temp_dir, 'comic.cb'
      fill cb_folder, 'a.jpg' => jpg, 'b.png' => png

      pages = described_class.load(cb_folder).arrange_pages %w[b.png a.jpg]

      expect(pages.map(&:path)).to eq %w[page_001.png page_002.jpg]
    end

    it 'raises for a missing source and changes nothing' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      expect { comic.arrange_pages %w[b.png nope.jpg] }.to raise_error ComicBook::Error, /does not exist/
      expect(described_class.load(folder).pages.map(&:path)).to eq %w[a.jpg b.png]
    end

    it 'raises for a source that is not an image' do
      fill folder, 'a.jpg' => jpg, 'notes.txt' => 'originals/with_info/notes.txt'

      expect { comic.arrange_pages %w[a.jpg notes.txt] }.to raise_error ComicBook::Error, /Unsupported file type: \.txt/
    end

    it 'refuses to arrange an archive' do
      archive = File.join temp_dir, 'simple.cbz'
      load_fixture('cbz/simple.cbz').copy_to archive

      expect { described_class.load(archive).arrange_pages %w[page1.jpg] }
        .to raise_error ComicBook::Error, /extract it first/
    end
  end

  describe '#arrange_pages with a template' do
    it 'uses page_001 names when given none' do
      expect(ComicBook::DEFAULT_PAGE_FILENAME_TEMPLATE).to eq 'page_{page:3}'
    end

    it 'names the pages from the template' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      pages = comic.arrange_pages %w[b.png a.jpg], template: 'scan-{page:4}'

      expect(pages.map(&:path)).to eq %w[scan-0001.png scan-0002.jpg]
      expect(contents_at('scan-0001.png')).to eq contents_of(png)
    end

    it "can use the comic's details" do
      FileUtils.cp_r File.join(__dir__, 'fixtures', 'originals', 'with_pages'), folder

      pages = comic.arrange_pages %w[page1.jpg page2.png page3.gif], template: '{series}_{number:3}_{page:4}'

      expect(pages.map(&:path)).to eq %w[Saga_007_0001.jpg Saga_007_0002.png Saga_007_0003.gif]
    end

    it 'leaves details out when there is no ComicInfo' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      pages = comic.arrange_pages %w[a.jpg b.png], template: '{series} {page:2}'

      expect(pages.map(&:path)).to eq %w[01.jpg 02.png]
    end

    it 'keeps pages apart when the template has no page number' do
      fill folder, 'a.jpg' => jpg, 'b.png' => png

      pages = comic.arrange_pages %w[b.png a.jpg], template: 'scan'

      expect(pages.map(&:path)).to eq %w[scan_1.png scan_2.jpg]
      expect(contents_at('scan_1.png')).to eq contents_of(png)
    end

    it 'keeps names in page order past nine pages' do
      # Eleven JPEGs, then a PNG as the last page so it can be told apart.
      (1..11).each { fill folder, format('p%02d.jpg', it) => jpg }
      fill folder, 'p12.png' => png

      pages = comic.arrange_pages comic.pages.map(&:path).reverse, template: 'p{page}'

      expect(pages.first.path).to eq 'p01.png'
      expect(pages.last.path).to eq 'p12.jpg'
      expect(contents_at('p01.png')).to eq contents_of(png)
    end
  end

  describe 'format support' do
    it 'lists every type' do
      expect(ComicBook::TYPES).to eq %i[cb cb7 cba cbr cbt cbz folder pdf]
    end

    it 'lists the types that can be opened' do
      expect(ComicBook::READABLE_TYPES).to eq %i[cb cb7 cbr cbt cbz folder pdf]
    end

    it 'lists the types that archive can produce' do
      expect(ComicBook::WRITABLE_TYPES).to eq %i[cb cb7 cbt cbz]
    end

    it 'can archive to every writable type' do
      fill folder, 'a.jpg' => jpg

      ComicBook::WRITABLE_TYPES.each do |type|
        output = described_class.load(folder).archive to: File.join(temp_dir, "out.#{type}")

        expect(described_class.load(output).type).to eq type
        fill folder, 'a.jpg' => jpg # archiving to .cb moves the folder
      end
    end
  end
end
