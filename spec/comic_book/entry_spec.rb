require 'spec_helper'

RSpec.describe ComicBook::Entry do
  describe '#name' do
    it 'is the basename of the path' do
      expect(described_class.new('subfolder/page1.jpg').name).to eq 'page1.jpg'
    end
  end

  describe '#image?' do
    it 'is true for image extensions, case-insensitively' do
      expect(described_class.new('page1.JPG')).to be_image
      expect(described_class.new('a/b/cover.webp')).to be_image
    end

    it 'is false for non-images' do
      expect(described_class.new('ComicInfo.xml')).not_to be_image
      expect(described_class.new('notes.txt')).not_to be_image
    end
  end

  describe '#info?' do
    it 'is true for ComicInfo.xml and MetronInfo.xml' do
      expect(described_class.new('ComicInfo.xml')).to be_info
      expect(described_class.new('sub/MetronInfo.xml')).to be_info
    end

    it 'is false otherwise' do
      expect(described_class.new('page1.jpg')).not_to be_info
      expect(described_class.new('notes.txt')).not_to be_info
    end
  end
end
