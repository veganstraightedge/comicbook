RSpec.describe ComicBook do
  it 'has a version number' do
    expect(Comicbook::VERSION).not_to be_nil
  end

  it 'does something useful' do
    expect(false).to be(true)
  end
end
