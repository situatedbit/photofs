require 'spec_helper'
require 'tag'
require 'tag_set'
require 'image'

describe PhotoFS::TagSet do
  let(:name) { 'ほっかいど' }
  let(:tags) { PhotoFS::TagSet.new }

  describe "find_or_create method" do
    it "should create a new tag object if non already exists" do
      expect(PhotoFS::Tag).to receive(:new).with(name)

      tags.find_or_create(name)
    end

    it "should return an existing tag object" do
      tag = tags.find_or_create(name)

      expect(tags.find_or_create name).to be(tag)
    end
  end

  describe "#find" do
    let(:tag) { PhotoFS::Tag.new name }

    context "passed a non-matching string" do
      it "it should return nil" do
        expect(tags.find 'garbage').to be nil
      end
    end

    context "passed a matching string" do
      before(:each) do
        allow(tags).to receive(:tags).and_return({tag.name => tag})
      end

      it "should return a tag" do
        expect(tags.find tag.name).to eq(tag)
      end
    end

    context "passed an empty array" do
      it "should return an empty array" do
        expect(tags.find []).to be_empty
      end
    end

    context "do passed an array of non-matching strings" do
      it "should return an empty array" do
        expect(tags.find ['garbage', 'trash']).to be_empty
      end
    end

    context "do passed an array of matching strings" do
      let(:tag2) { PhotoFS::Tag.new(name * 2) }
      let(:search_tags) { [tag.name, tag2.name] }

      before(:each) do
        allow(tags).to receive(:tags).and_return({tag.name => tag, tag2.name => tag2})
      end

      it "should return an array of matching tags" do
        expect(tags.find search_tags).to contain_exactly(tag, tag2)
      end
    end
  end

  describe "#find_intersection" do
    let(:tags_hash) { Hash.new }
    let(:first) { PhotoFS::Tag.new('first') }
    let(:second) { PhotoFS::Tag.new('second') }
    let(:first_images) { [1, 2, 3].map { |i| PhotoFS::Image.new(i.to_s) } }
    let(:second_images) { [3, 4, 5].map { |i| PhotoFS::Image.new(i.to_s) } }

    before(:each) do    
      first_images.each { |i| first.add(i) }
      second_images.each { |i| second.add(i) }
    end

    it "should respond to an empty array with an empty set" do
      allow(tags).to receive(:find).with([]).and_return([])

      expect(tags.find_intersection([])).to be_empty
    end

    it "should return an empty set for tags that don't exist" do
      allow(tags).to receive(:find).with(['garbage']).and_return([])

      expect(tags.find_intersection ['garbage']).to be_empty
    end

    it "should do a simple find for an array of size one" do
      allow(tags).to receive(:find).with([first.name]).and_return([first])

      expect(tags.find_intersection([first.name])).to contain_exactly(*first_images)
    end

    it "should create an intersection set from the tags that are returned" do
      allow(tags).to receive(:find).with([first.name, second.name]).and_return([first, second])

      expect(tags.find_intersection [first.name, second.name]).to contain_exactly(PhotoFS::Image.new('3'))
    end
  end
end
