require 'spec_helper'

RSpec.describe ComicBook::Adapter::Base do
  subject(:adapter) { described_class.new('/path/to/test') }

  describe '#initialize' do
    it 'stores absolute path' do
      expect(adapter.send(:path)).to eq File.expand_path('/path/to/test')
    end
  end

  describe '#archive' do
    it 'raises NotImplementedError' do
      expect do
        adapter.archive('/source')
      end.to raise_error(NotImplementedError, 'ComicBook::Adapter::Base must implement #archive')
    end
  end

  describe '#extract' do
    it 'raises NotImplementedError' do
      expect do
        adapter.extract('/destination')
      end.to raise_error(NotImplementedError, 'ComicBook::Adapter::Base must implement #extract')
    end
  end

  describe '#pages' do
    it 'raises NotImplementedError' do
      expect { adapter.pages }.to raise_error(NotImplementedError, 'ComicBook::Adapter::Base must implement #pages')
    end
  end
end
