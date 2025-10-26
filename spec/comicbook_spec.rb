# frozen_string_literal: true

RSpec.describe Comicbook do
  it "has a version number" do
    expect(Comicbook::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
