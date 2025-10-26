require 'spec_helper'

RSpec.describe ComicBook::Page do
  subject(:page) { described_class.new path: file_path, name: file_name }

  let(:file_path) { '/path/to/page1.jpg' }
  let(:file_name) { 'page1.jpg' }

  describe '#initialize' do
    it 'sets path and name' do
      expect(page.path).to eq file_path
      expect(page.name).to eq file_name
    end
  end

  describe '#path' do
    it 'returns the file path' do
      expect(page.path).to eq file_path
    end
  end

  describe '#name' do
    it 'returns the file name' do
      expect(page.name).to eq file_name
    end
  end
end
