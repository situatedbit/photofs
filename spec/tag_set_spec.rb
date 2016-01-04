require 'spec_helper'
require 'tag'
require 'tag_set'

describe PhotoFS::TagSet do
  let(:name) { 'ほっかいど' }
  let(:tags) { PhotoFS::TagSet.new }

  describe "find method" do
    it "should create a new tag object if non already exists" do
      expect(PhotoFS::Tag).to receive(:new).with(name)

      tags.find(name)
    end

    it "should return an existing tag object" do
      tag = tags.find(name)

      expect(tags.find name).to be(tag)
    end
  end
end
