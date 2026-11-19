require 'spec_helper'

RSpec.describe ComicBook::Signature do
  let(:fixtures) { File.join __dir__, '..', 'fixtures' }

  def type_of fixture
    described_class.new(File.join(fixtures, fixture)).type
  end

  describe '#type' do
    it 'recognizes a ZIP' do
      expect(type_of('cbz/simple.cbz')).to eq :cbz
      expect(type_of('cbz/empty.cbz')).to  eq :cbz
    end

    it 'recognizes a RAR' do
      expect(type_of('cbr/simple.cbr')).to eq :cbr
    end

    it 'recognizes a 7-Zip' do
      expect(type_of('cb7/simple.cb7')).to eq :cb7
    end

    it 'recognizes a TAR' do
      expect(type_of('cbt/simple.cbt')).to eq :cbt
    end

    it 'recognizes a PDF' do
      expect(type_of('pdf/simple.pdf')).to eq :pdf
    end

    it 'recognizes an ACE' do
      expect(type_of('signatures/ace_header.cba')).to eq :cba
    end

    it 'is nil for a file that starts like none of the formats' do
      expect(type_of('signatures/not_an_archive.cbz')).to be_nil
      expect(type_of('originals/simple/page1.jpg')).to    be_nil
    end

    it 'is nil for a TAR with no ustar marker' do
      expect(type_of('cbt/empty.cbt')).to be_nil
    end

    it 'is nil for a file that cannot be read' do
      expect(type_of('signatures/missing.cbz')).to be_nil
      expect(described_class.new(fixtures).type).to be_nil
    end
  end
end
