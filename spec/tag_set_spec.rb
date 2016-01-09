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

  describe "#find_by_name" do
    let(:tag) { PhotoFS::Tag.new name }

    context "passed a non-matching string" do
      it "it should return nil" do
        expect(tags.find_by_name 'garbage').to be nil
      end
    end

    context "passed a matching string" do
      before(:each) do
        tags.instance_variable_set(:@tags, {tag.name => tag})
      end

      it "should return a tag" do
        expect(tags.find_by_name tag.name).to eq(tag)
      end
    end

    context "passed an empty array" do
      it "should return an empty array" do
        expect(tags.find_by_name []).to be_empty
      end
    end

    context "do passed an array of non-matching strings" do
      it "should return an empty array" do
        expect(tags.find_by_name ['garbage', 'trash']).to be_empty
      end
    end

    context "do passed an array of matching strings" do
      let(:tag2) { PhotoFS::Tag.new(name * 2) }
      let(:search_tags) { [tag.name, tag2.name] }

      before(:each) do
        tags.instance_variable_set(:@tags, {tag.name => tag, tag2.name => tag2})
      end

      it "should return an array of matching tags" do
        expect(tags.find_by_name search_tags).to contain_exactly(tag, tag2)
      end
    end
  end

  describe "#find_by_image" do
    let(:image) { PhotoFS::Image.new 'ちよだ' }
    let(:tag) { PhotoFS::Tag.new 'タグ' }

    context "when there are no tags" do
      before(:each) do
        allow(tags).to receive(:image_tags_hash).and_return({})
      end

      it "should return an empty collection" do
        expect(tags.find_by_image image).to be_empty
      end
    end

    context "when passed a single image" do
      before(:each) do
        allow(tags).to receive(:image_tags_hash).and_return({ image => [tag] })
      end

      it "should return the tags for that image" do
        expect(tags.find_by_image image).to contain_exactly(tag)
      end
    end

    context "when there are multiple images" do
      let(:image2) { 'image2' }
      let(:tag2) { 'tag2' }
      let(:tag3) { 'tag3' }

      before(:each) do
        hash = { image => [tag, tag2], image2 => [tag2, tag3] }
        allow(tags).to receive(:image_tags_hash).and_return(hash)
      end

      it "should return the union of tags from those images" do
        expect(tags.find_by_image [image, image2]).to contain_exactly(tag, tag2, tag3)
      end
    end
  end

  describe "#intersection" do
    let(:first) { PhotoFS::Tag.new('first') }
    let(:second) { PhotoFS::Tag.new('second') }
    let(:first_images) { [1, 2, 3].map { |i| PhotoFS::Image.new(i.to_s) } }
    let(:second_images) { [3, 4, 5].map { |i| PhotoFS::Image.new(i.to_s) } }

    before(:each) do    
      first_images.each { |i| first.add(i) }
      second_images.each { |i| second.add(i) }
    end

    it "should respond to an empty array with an empty set" do
      expect(PhotoFS::TagSet.intersection([]).all).to be_empty
    end

    it "should return an empty set for tags that don't exist" do
      expect(PhotoFS::TagSet.intersection([PhotoFS::Tag.new('garbage')]).all).to be_empty
    end

    it "should do a simple find for an array of size one" do
      expect(PhotoFS::TagSet.intersection([first]).all).to contain_exactly(*first_images)
    end

    it "should create an intersection set from the tags that are returned" do
      expect(PhotoFS::TagSet.intersection([first, second]).all).to contain_exactly(PhotoFS::Image.new('3'))
    end
  end

  describe "#image_tags_hash" do
    context "when there are no images" do
      let :tags_hash do
        Hash[ ['a', 'b', 'c'].map { |n| [n, PhotoFS::Tag.new(n)] } ]
      end

      before(:each) do
        tags.instance_variable_set(:@tags, tags_hash)
      end

      it "should be empty" do
        expect(tags.send :image_tags_hash).to be_empty
      end
    end

    context "when there are no tags" do
      before(:each) do
        tags.instance_variable_set(:@tags, {})
      end

      it "should be empty" do
        expect(tags.send :image_tags_hash).to be_empty
      end
    end

    context "when there are images with multiple tags" do
      let(:tag1) { PhotoFS::Tag.new('a') }
      let(:tag2) { PhotoFS::Tag.new('b') }
      let(:tag3) { PhotoFS::Tag.new('c') }

      let(:image1) { PhotoFS::Image.new('1') }
      let(:image2) { PhotoFS::Image.new('2') }
      let(:image3) { PhotoFS::Image.new('3') }

      let(:tags_hash) do
        { tag1.name => tag1, tag2.name => tag2, tag3.name => tag3 }
      end

      before(:each) do
        allow(tag1).to receive(:images).and_return([image1, image2])
        allow(tag2).to receive(:images).and_return([image2, image3])
        allow(tag3).to receive(:images).and_return([image3])

        tags.instance_variable_set(:@tags, tags_hash)
      end

      it "should flip keys and values" do
        expect((tags.send :image_tags_hash)[image1]).to contain_exactly(tag1)
        expect((tags.send :image_tags_hash)[image2]).to contain_exactly(tag1, tag2)
        expect((tags.send :image_tags_hash)[image3]).to contain_exactly(tag2, tag3)
      end
    end
  end

  describe '#delete' do
    let(:tag) { PhotoFS::Tag.new 'test' }

    it 'proxies the delete call to internal hash storage' do
      expect(tags.instance_variable_get(:@tags)).to receive(:delete).with(tag.name)

      tags.delete tag
    end
  end
end
