require 'spec_helper'
require 'tag'

describe PhotoFS::Tag do
  let(:name) { 'kawaguchiko' }

  it "should include a name" do
    expect(PhotoFS::Tag.new(name).name).to eq(name)
  end
end
