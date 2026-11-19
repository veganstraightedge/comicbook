require 'spec_helper'

# A comic's type comes from what the file is, not what it is named:
# mislabelled archives are common (a RAR named `.cbz`).
RSpec.describe ComicBook do
  let(:temp_dir)   { Dir.mktmpdir }
  let(:page_names) { %w[page1.jpg page2.png page3.gif] }

  after do
    FileUtils.rm_rf temp_dir
  end

  # A copy of a fixture under another name, in the temp directory.
  def misnamed fixture, as:
    path = File.join temp_dir, as
    load_fixture(fixture).copy_to path
    path
  end

  it 'reads a RAR named .cbz as a CBR' do
    comic = described_class.load misnamed('cbr/simple.cbr', as: 'comic.cbz')

    expect(comic.type).to eq :cbr
    expect(comic.pages.map(&:name)).to eq page_names
  end

  it 'reads a ZIP named .cbr as a CBZ' do
    comic = described_class.load misnamed('cbz/simple.cbz', as: 'comic.cbr')

    expect(comic.type).to eq :cbz
    expect(comic.pages.map(&:name)).to eq page_names
  end

  it 'reads a 7-Zip named .cbz as a CB7' do
    comic = described_class.load misnamed('cb7/simple.cb7', as: 'comic.cbz')

    expect(comic.type).to eq :cb7
    expect(comic.pages.map(&:name)).to eq page_names
  end

  it 'reads a TAR named .cbz as a CBT' do
    comic = described_class.load misnamed('cbt/simple.cbt', as: 'comic.cbz')

    expect(comic.type).to eq :cbt
    expect(comic.pages.map(&:name)).to eq page_names
  end

  it 'reads a PDF named .cbz as a PDF' do
    comic = described_class.load misnamed('pdf/simple.pdf', as: 'comic.cbz')

    expect(comic.type).to eq :pdf
  end

  it 'keeps the type of correctly named archives' do
    expect(described_class.load(misnamed('cbz/simple.cbz', as: 'comic.cbz')).type).to eq :cbz
    expect(described_class.load(misnamed('cb7/simple.cb7', as: 'comic.cb7')).type).to eq :cb7
    expect(described_class.load(misnamed('cbt/simple.cbt', as: 'comic.cbt')).type).to eq :cbt
    expect(described_class.load(misnamed('cbr/simple.cbr', as: 'comic.cbr')).type).to eq :cbr
  end

  it 'goes by the name when the contents are not recognized' do
    expect(described_class.load(misnamed('signatures/not_an_archive.cbz', as: 'comic.cbz')).type).to eq :cbz
    expect(described_class.load(misnamed('cbt/empty.cbt', as: 'comic.cbt')).type).to eq :cbt
  end

  it 'still refuses a file whose name is not a comic, whatever it contains' do
    zip = misnamed 'cbz/simple.cbz', as: 'comic.zip'

    expect { described_class.load zip }.to raise_error ComicBook::Error, /Unsupported file type/
  end

  it 'extracts a mislabelled archive as what it is' do
    comic       = described_class.load misnamed('cbr/simple.cbr', as: 'comic.cbz')
    destination = comic.extract to: File.join(temp_dir, 'extracted.cb')

    expect(Dir.children(destination).sort).to eq page_names
  end
end
